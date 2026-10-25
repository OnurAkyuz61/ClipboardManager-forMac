//
//  DevConverter.swift
//  Clipboard Manager
//
//  JSON / Base64 / URL-encode / HEX renk dönüştürücüleri (Sandbox uyumlu).
//

import Foundation
import AppKit

/// Geliştirici odaklı pano dönüşüm araçları
enum DevConverter {
    
    // MARK: - Content detection
    
    nonisolated static func detectContentKind(_ text: String) -> ClipboardContentKind {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if isValidJSON(trimmed) {
            return .json
        }
        if let hex = parseHexColor(trimmed) {
            return .hexColor(hex: hex)
        }
        if URLSanitizer.sanitize(trimmed) != nil {
            return .url
        }
        if looksLikeBase64(trimmed), decodeBase64(trimmed) != nil {
            return .base64
        }
        if looksLikeURLEncoded(trimmed), let decoded = decodeURLEncoded(trimmed), decoded != trimmed {
            return .urlEncoded
        }
        return .plain
    }
    
    // MARK: - JSON
    
    nonisolated static func isValidJSON(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = trimmed.data(using: .utf8) else { return false }
        guard let obj = try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]) else {
            return false
        }
        // Sadece object veya array — tekil string/number JSON fragment'lerini atla
        return obj is [String: Any] || obj is [Any]
    }
    
    nonisolated static func prettyJSON(_ text: String) -> String? {
        guard let object = jsonObject(from: text),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]),
              let pretty = String(data: data, encoding: .utf8)
        else { return nil }
        return pretty
    }
    
    nonisolated static func minifyJSON(_ text: String) -> String? {
        guard let object = jsonObject(from: text),
              let data = try? JSONSerialization.data(withJSONObject: object, options: []),
              let minified = String(data: data, encoding: .utf8)
        else { return nil }
        return minified
    }
    
    nonisolated static func toSwiftStruct(_ text: String, name: String = "Root") -> String? {
        guard let object = jsonObject(from: text) else { return nil }
        return generateSwift(name: sanitizeTypeName(name), value: object, indent: 0)
    }
    
    nonisolated static func toTypeScriptInterface(_ text: String, name: String = "Root") -> String? {
        guard let object = jsonObject(from: text) else { return nil }
        return generateTypeScript(name: sanitizeTypeName(name), value: object, indent: 0)
    }
    
    nonisolated static func toCSharpClass(_ text: String, name: String = "Root") -> String? {
        guard let object = jsonObject(from: text) else { return nil }
        return generateCSharp(name: sanitizeTypeName(name), value: object, indent: 0)
    }
    
    // MARK: - Base64 / URL encode
    
    nonisolated static func looksLikeBase64(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 8, trimmed.count % 4 == 0 else { return false }
        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=")
        return trimmed.unicodeScalars.allSatisfy { allowed.contains($0) }
    }
    
    nonisolated static func decodeBase64(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = Data(base64Encoded: trimmed),
              let decoded = String(data: data, encoding: .utf8),
              !decoded.isEmpty
        else { return nil }
        return decoded
    }
    
    nonisolated static func looksLikeURLEncoded(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.contains("%") || (trimmed.contains("+") && trimmed.contains("="))
    }
    
    nonisolated static func decodeURLEncoded(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.removingPercentEncoding
    }
    
    // MARK: - HEX color
    
    /// Geçerli HEX ise normalize `#RRGGBB` döner
    nonisolated static func parseHexColor(_ text: String) -> String? {
        var hex = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if hex.hasPrefix("#") { hex.removeFirst() }
        guard hex.count == 3 || hex.count == 6 || hex.count == 8 else { return nil }
        guard hex.unicodeScalars.allSatisfy({ CharacterSet(charactersIn: "0123456789abcdefABCDEF").contains($0) }) else {
            return nil
        }
        if hex.count == 3 {
            hex = hex.map { "\($0)\($0)" }.joined()
        }
        return "#" + hex.uppercased().prefix(6)
    }
    
    static func nsColor(fromHex hex: String) -> NSColor? {
        var value = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.hasPrefix("#") { value.removeFirst() }
        guard value.count == 6, let intVal = UInt64(value, radix: 16) else { return nil }
        let r = CGFloat((intVal >> 16) & 0xFF) / 255.0
        let g = CGFloat((intVal >> 8) & 0xFF) / 255.0
        let b = CGFloat(intVal & 0xFF) / 255.0
        return NSColor(calibratedRed: r, green: g, blue: b, alpha: 1.0)
    }
    
    // MARK: - JSON helpers
    
    nonisolated private static func jsonObject(from text: String) -> Any? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = trimmed.data(using: .utf8) else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
    }
    
    nonisolated private static func sanitizeTypeName(_ name: String) -> String {
        let cleaned = name.filter { $0.isLetter || $0.isNumber }
        if cleaned.isEmpty { return "Root" }
        if let first = cleaned.first, first.isNumber {
            return "T" + cleaned
        }
        return cleaned.prefix(1).uppercased() + cleaned.dropFirst()
    }
    
    nonisolated private static func swiftPropertyName(_ key: String) -> String {
        let parts = key.split { !$0.isLetter && !$0.isNumber }
        guard let first = parts.first else { return "value" }
        let rest = parts.dropFirst().map { $0.prefix(1).uppercased() + $0.dropFirst() }.joined()
        var name = first.lowercased() + rest
        let keywords: Set<String> = ["class", "struct", "enum", "var", "let", "return", "import", "default", "extension", "protocol", "static", "func", "init", "self", "Type", "type"]
        if keywords.contains(name) { name = "`\(name)`" }
        return name
    }
    
    nonisolated private static func indentString(_ level: Int) -> String {
        String(repeating: "    ", count: level)
    }
    
    // MARK: - Swift codegen
    
    nonisolated private static func generateSwift(name: String, value: Any, indent: Int) -> String {
        let pad = indentString(indent)
        
        if let dict = value as? [String: Any] {
            var nested: [String] = []
            var props: [String] = []
            
            for key in dict.keys.sorted() {
                let prop = swiftPropertyName(key)
                let (typeName, nestedCode) = swiftType(for: dict[key]!, preferredName: sanitizeTypeName(key), indent: indent)
                props.append("\(pad)    let \(prop): \(typeName)")
                if let nestedCode { nested.append(nestedCode) }
            }
            
            var result = "\(pad)struct \(name): Codable {\n"
            result += props.joined(separator: "\n")
            result += "\n\(pad)}"
            if !nested.isEmpty {
                result += "\n\n" + nested.joined(separator: "\n\n")
            }
            return result
        }
        
        if let array = value as? [Any], let first = array.first {
            let (elementType, nested) = swiftType(for: first, preferredName: name + "Item", indent: indent)
            var result = "\(pad)// Root is an array — wrapping element type\n"
            result += "\(pad)typealias \(name) = [\(elementType)]"
            if let nested { result += "\n\n" + nested }
            return result
        }
        
        return "\(pad)struct \(name): Codable {}"
    }
    
    nonisolated private static func swiftType(for value: Any, preferredName: String, indent: Int) -> (String, String?) {
        switch value {
        case is NSNull:
            return ("String?", nil)
        case is String:
            return ("String", nil)
        case let num as NSNumber:
            // Bool is bridged as NSNumber
            let cf = CFGetTypeID(num as CFTypeRef)
            if cf == CFBooleanGetTypeID() {
                return ("Bool", nil)
            }
            let d = num.doubleValue
            if d.rounded() == d, abs(d) <= Double(Int.max) {
                return ("Int", nil)
            }
            return ("Double", nil)
        case let dict as [String: Any]:
            let code = generateSwift(name: preferredName, value: dict, indent: indent)
            return (preferredName, code)
        case let array as [Any]:
            if let first = array.first {
                let (el, nested) = swiftType(for: first, preferredName: preferredName + "Item", indent: indent)
                return ("[\(el)]", nested)
            }
            return ("[String]", nil)
        default:
            return ("String", nil)
        }
    }
    
    // MARK: - TypeScript codegen
    
    nonisolated private static func generateTypeScript(name: String, value: Any, indent: Int) -> String {
        let pad = indentString(indent)
        
        if let dict = value as? [String: Any] {
            var nested: [String] = []
            var props: [String] = []
            
            for key in dict.keys.sorted() {
                let (typeName, nestedCode) = tsType(for: dict[key]!, preferredName: sanitizeTypeName(key), indent: indent)
                let safeKey = key.range(of: #"^[A-Za-z_][A-Za-z0-9_]*$"#, options: .regularExpression) != nil
                    ? key
                    : "\"\(key)\""
                props.append("\(pad)  \(safeKey): \(typeName);")
                if let nestedCode { nested.append(nestedCode) }
            }
            
            var result = "\(pad)export interface \(name) {\n"
            result += props.joined(separator: "\n")
            result += "\n\(pad)}"
            if !nested.isEmpty {
                result += "\n\n" + nested.joined(separator: "\n\n")
            }
            return result
        }
        
        if let array = value as? [Any], let first = array.first {
            let (el, nested) = tsType(for: first, preferredName: name + "Item", indent: indent)
            var result = "\(pad)export type \(name) = \(el)[];"
            if let nested { result += "\n\n" + nested }
            return result
        }
        
        return "\(pad)export interface \(name) {}"
    }
    
    nonisolated private static func tsType(for value: Any, preferredName: String, indent: Int) -> (String, String?) {
        switch value {
        case is NSNull:
            return ("null", nil)
        case is String:
            return ("string", nil)
        case let num as NSNumber:
            let cf = CFGetTypeID(num as CFTypeRef)
            if cf == CFBooleanGetTypeID() {
                return ("boolean", nil)
            }
            return ("number", nil)
        case let dict as [String: Any]:
            let code = generateTypeScript(name: preferredName, value: dict, indent: indent)
            return (preferredName, code)
        case let array as [Any]:
            if let first = array.first {
                let (el, nested) = tsType(for: first, preferredName: preferredName + "Item", indent: indent)
                return ("\(el)[]", nested)
            }
            return ("unknown[]", nil)
        default:
            return ("unknown", nil)
        }
    }
    
    // MARK: - C# codegen
    
    nonisolated private static func generateCSharp(name: String, value: Any, indent: Int) -> String {
        let pad = indentString(indent)
        
        if let dict = value as? [String: Any] {
            var nested: [String] = []
            var props: [String] = []
            
            for key in dict.keys.sorted() {
                let propName = sanitizeTypeName(key)
                let (typeName, nestedCode) = csharpType(for: dict[key]!, preferredName: propName, indent: indent)
                props.append("\(pad)    public \(typeName) \(propName) { get; set; }")
                if let nestedCode { nested.append(nestedCode) }
            }
            
            var result = "\(pad)public class \(name)\n\(pad){\n"
            result += props.joined(separator: "\n")
            result += "\n\(pad)}"
            if !nested.isEmpty {
                result += "\n\n" + nested.joined(separator: "\n\n")
            }
            return result
        }
        
        if let array = value as? [Any], let first = array.first {
            let (el, nested) = csharpType(for: first, preferredName: name + "Item", indent: indent)
            var result = "\(pad)// Root is an array\n\(pad)// Use List<\(el)>"
            if let nested { result += "\n\n" + nested }
            return result
        }
        
        return "\(pad)public class \(name)\n\(pad){\n\(pad)}"
    }
    
    nonisolated private static func csharpType(for value: Any, preferredName: String, indent: Int) -> (String, String?) {
        switch value {
        case is NSNull:
            return ("string?", nil)
        case is String:
            return ("string", nil)
        case let num as NSNumber:
            let cf = CFGetTypeID(num as CFTypeRef)
            if cf == CFBooleanGetTypeID() {
                return ("bool", nil)
            }
            let d = num.doubleValue
            if d.rounded() == d, abs(d) <= Double(Int.max) {
                return ("int", nil)
            }
            return ("double", nil)
        case let dict as [String: Any]:
            let code = generateCSharp(name: preferredName, value: dict, indent: indent)
            return (preferredName, code)
        case let array as [Any]:
            if let first = array.first {
                let (el, nested) = csharpType(for: first, preferredName: preferredName + "Item", indent: indent)
                return ("List<\(el)>", nested)
            }
            return ("List<string>", nil)
        default:
            return ("string", nil)
        }
    }
}
