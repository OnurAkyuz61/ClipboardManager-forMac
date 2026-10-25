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
        
        if let jwt = decodeJWT(trimmed) {
            return .jwtToken(header: jwt.header, payload: jwt.payload)
        }
        if looksLikeCurl(trimmed) {
            return .curlCommand
        }
        if let dateString = formatUnixTimestamp(trimmed) {
            return .unixTimestamp(dateString: dateString)
        }
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
    
    // MARK: - JWT
    
    nonisolated static func looksLikeJWT(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmed.split(separator: ".")
        guard parts.count == 3, trimmed.hasPrefix("eyJ") else { return false }
        return decodeBase64URL(String(parts[0])) != nil && decodeBase64URL(String(parts[1])) != nil
    }
    
    /// Header + Payload'ı Base64URL decode edip (mümkünse) pretty JSON döner
    nonisolated static func decodeJWT(_ text: String) -> (header: String, payload: String)? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard looksLikeJWT(trimmed) else { return nil }
        let parts = trimmed.split(separator: ".")
        guard parts.count >= 2,
              let headerRaw = decodeBase64URL(String(parts[0])),
              let payloadRaw = decodeBase64URL(String(parts[1]))
        else { return nil }
        return (
            prettyJSON(headerRaw) ?? headerRaw,
            prettyJSON(payloadRaw) ?? payloadRaw
        )
    }
    
    nonisolated static func decodeBase64URL(_ input: String) -> String? {
        var base64 = input
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let remainder = base64.count % 4
        if remainder > 0 {
            base64.append(String(repeating: "=", count: 4 - remainder))
        }
        guard let data = Data(base64Encoded: base64),
              let str = String(data: data, encoding: .utf8)
        else { return nil }
        return str
    }
    
    // MARK: - cURL
    
    nonisolated static func looksLikeCurl(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.lowercased().hasPrefix("curl ")
    }
    
    nonisolated struct CurlRequest: Sendable {
        var method: String
        var url: String
        var headers: [(String, String)]
        var body: String?
    }
    
    nonisolated static func parseCurl(_ text: String) -> CurlRequest? {
        guard looksLikeCurl(text) else { return nil }
        let tokens = tokenizeShell(text.trimmingCharacters(in: .whitespacesAndNewlines))
        guard !tokens.isEmpty else { return nil }
        
        var method = "GET"
        var url = ""
        var headers: [(String, String)] = []
        var body: String?
        var i = 0
        
        while i < tokens.count {
            let t = tokens[i]
            if t == "curl" {
                i += 1
                continue
            }
            if t == "-X" || t == "--request", i + 1 < tokens.count {
                method = tokens[i + 1].uppercased()
                i += 2
                continue
            }
            if t == "-H" || t == "--header", i + 1 < tokens.count {
                let header = tokens[i + 1]
                if let colon = header.firstIndex(of: ":") {
                    let name = String(header[..<colon]).trimmingCharacters(in: .whitespaces)
                    let value = String(header[header.index(after: colon)...]).trimmingCharacters(in: .whitespaces)
                    headers.append((name, value))
                }
                i += 2
                continue
            }
            if t == "-d" || t == "--data" || t == "--data-raw" || t == "--data-binary", i + 1 < tokens.count {
                body = tokens[i + 1]
                if method == "GET" { method = "POST" }
                i += 2
                continue
            }
            if t.hasPrefix("http://") || t.hasPrefix("https://") {
                url = t
                i += 1
                continue
            }
            // `-XPOST` gibi birleşik bayraklar
            if t.hasPrefix("-X"), t.count > 2 {
                method = String(t.dropFirst(2)).uppercased()
                i += 1
                continue
            }
            i += 1
        }
        
        guard !url.isEmpty else { return nil }
        return CurlRequest(method: method, url: url, headers: headers, body: body)
    }
    
    nonisolated static func curlToSwiftURLRequest(_ text: String) -> String? {
        guard let req = parseCurl(text) else { return nil }
        var lines: [String] = []
        lines.append("var request = URLRequest(url: URL(string: \"\(escapeSwift(req.url))\")!)")
        lines.append("request.httpMethod = \"\(req.method)\"")
        for (name, value) in req.headers {
            lines.append("request.setValue(\"\(escapeSwift(value))\", forHTTPHeaderField: \"\(escapeSwift(name))\")")
        }
        if let body = req.body {
            lines.append("request.httpBody = \"\"\"")
            lines.append(body)
            lines.append("\"\"\".data(using: .utf8)")
        }
        return lines.joined(separator: "\n")
    }
    
    nonisolated static func curlToJSFetch(_ text: String) -> String? {
        guard let req = parseCurl(text) else { return nil }
        var headerLines = req.headers.map { "    \"\(escapeJS($0.0))\": \"\(escapeJS($0.1))\"" }.joined(separator: ",\n")
        if headerLines.isEmpty { headerLines = "" }
        
        var opts: [String] = ["  method: \"\(req.method)\""]
        if !req.headers.isEmpty {
            opts.append("  headers: {\n\(headerLines)\n  }")
        }
        if let body = req.body {
            opts.append("  body: \(jsStringLiteral(body))")
        }
        
        return "fetch(\"\(escapeJS(req.url))\", {\n\(opts.joined(separator: ",\n"))\n});"
    }
    
    // MARK: - Unix timestamp
    
    nonisolated static func formatUnixTimestamp(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = Int64(trimmed) else { return nil }
        let digits = trimmed.count
        guard digits == 10 || digits == 13 else { return nil }
        
        let seconds: TimeInterval
        if digits == 13 {
            seconds = TimeInterval(value) / 1000.0
        } else {
            seconds = TimeInterval(value)
        }
        
        // Makul aralık: ~2001 … ~2100
        guard seconds > 1_000_000_000, seconds < 4_102_444_800 else { return nil }
        
        let date = Date(timeIntervalSince1970: seconds)
        let local = DateFormatter()
        local.dateStyle = .medium
        local.timeStyle = .medium
        local.timeZone = .current
        
        let utc = DateFormatter()
        utc.dateStyle = .medium
        utc.timeStyle = .medium
        utc.timeZone = TimeZone(secondsFromGMT: 0)
        utc.locale = Locale(identifier: "en_US_POSIX")
        
        return "\(local.string(from: date))  |  UTC \(utc.string(from: date))"
    }
    
    nonisolated static func unixTimestampToISO8601(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = Int64(trimmed) else { return nil }
        let digits = trimmed.count
        guard digits == 10 || digits == 13 else { return nil }
        let seconds: TimeInterval = digits == 13 ? TimeInterval(value) / 1000.0 : TimeInterval(value)
        guard seconds > 1_000_000_000, seconds < 4_102_444_800 else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = Date(timeIntervalSince1970: seconds)
        let result = formatter.string(from: date)
        if result.isEmpty {
            let fallback = ISO8601DateFormatter()
            fallback.formatOptions = [.withInternetDateTime]
            return fallback.string(from: date)
        }
        return result
    }
    
    // MARK: - Case converters
    
    nonisolated static func toCamelCase(_ text: String) -> String {
        let words = splitWords(text)
        guard let first = words.first else { return text }
        return first.lowercased() + words.dropFirst().map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }.joined()
    }
    
    nonisolated static func toSnakeCase(_ text: String) -> String {
        splitWords(text).map { $0.lowercased() }.joined(separator: "_")
    }
    
    nonisolated static func toKebabCase(_ text: String) -> String {
        splitWords(text).map { $0.lowercased() }.joined(separator: "-")
    }
    
    nonisolated static func toUpperSnakeCase(_ text: String) -> String {
        splitWords(text).map { $0.uppercased() }.joined(separator: "_")
    }
    
    nonisolated private static func splitWords(_ text: String) -> [String] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        // camelCase / PascalCase ayrıştır
        var spaced = ""
        for (i, ch) in trimmed.enumerated() {
            if ch.isUppercase, i > 0 {
                spaced.append(" ")
            }
            if ch == "_" || ch == "-" || ch == " " || ch == "." {
                spaced.append(" ")
            } else {
                spaced.append(ch)
            }
        }
        return spaced.split(whereSeparator: { $0.isWhitespace }).map(String.init).filter { !$0.isEmpty }
    }
    
    nonisolated private static func tokenizeShell(_ input: String) -> [String] {
        var tokens: [String] = []
        var current = ""
        var quote: Character?
        var escaped = false
        
        for ch in input {
            if escaped {
                current.append(ch)
                escaped = false
                continue
            }
            if ch == "\\" {
                escaped = true
                continue
            }
            if let q = quote {
                if ch == q {
                    quote = nil
                } else {
                    current.append(ch)
                }
                continue
            }
            if ch == "\"" || ch == "'" {
                quote = ch
                continue
            }
            if ch.isWhitespace {
                if !current.isEmpty {
                    tokens.append(current)
                    current = ""
                }
                continue
            }
            current.append(ch)
        }
        if !current.isEmpty { tokens.append(current) }
        return tokens
    }
    
    nonisolated private static func escapeSwift(_ s: String) -> String {
        s.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
    
    nonisolated private static func escapeJS(_ s: String) -> String {
        s.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
    }
    
    nonisolated private static func jsStringLiteral(_ s: String) -> String {
        "\"\(escapeJS(s))\""
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
