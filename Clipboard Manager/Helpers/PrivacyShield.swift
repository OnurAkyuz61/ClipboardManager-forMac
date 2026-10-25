//
//  PrivacyShield.swift
//  Clipboard Manager
//
//  Hassas veri tespiti ve gizlilik kalkanı (Sandbox uyumlu, yerel regex).
//

import Foundation

/// Kopyalanan metinde JWT, API key, .env ve kart numarası tespiti
enum PrivacyShield {
    
    // MARK: - Patterns
    
    private static let jwtPattern = #"^eyJ[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]*$"#
    
    private static let apiKeyPatterns: [String] = [
        #"\bsk_live_[A-Za-z0-9]{20,}\b"#,
        #"\bsk_test_[A-Za-z0-9]{20,}\b"#,
        #"\bghp_[A-Za-z0-9]{36,}\b"#,
        #"\bgho_[A-Za-z0-9]{36,}\b"#,
        #"\bghu_[A-Za-z0-9]{36,}\b"#,
        #"\bghs_[A-Za-z0-9]{36,}\b"#,
        #"\bghr_[A-Za-z0-9]{36,}\b"#,
        #"\bAIza[0-9A-Za-z\-_]{35}\b"#,
        #"\bAKIA[0-9A-Z]{16}\b"#,
        #"\bxox[baprs]-[A-Za-z0-9-]{10,}\b"#,
        #"\bAC[a-zA-Z0-9]{32}\b"#, // Twilio-ish
        #"\bSG\.[A-Za-z0-9_\-]{22}\.[A-Za-z0-9_\-]{43}\b"# // SendGrid
    ]
    
    private static let envLinePattern = #"^[A-Za-z_][A-Za-z0-9_]*\s*=\s*.+$"#
    private static let cardDigitPattern = #"\b(?:\d[ -]*?){13,19}\b"#
    
    // MARK: - Public
    
    /// Metinde hassas veri varsa türünü döner (öncelik sırasıyla).
    nonisolated static func detect(_ text: String) -> SensitiveKind? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        
        if matches(jwtPattern, in: trimmed, fullMatch: true) {
            return .jwt
        }
        
        if isEnvFile(trimmed) {
            return .envFile
        }
        
        for pattern in apiKeyPatterns {
            if matches(pattern, in: trimmed, fullMatch: false) {
                return .apiKey
            }
        }
        
        if containsValidCreditCard(trimmed) {
            return .creditCard
        }
        
        return nil
    }
    
    /// Maskelenmiş gösterim
    nonisolated static func maskedDisplay(for text: String) -> String {
        String(repeating: "•", count: min(max(text.count, 8), 24))
    }
    
    // MARK: - Private helpers
    
    nonisolated private static func matches(_ pattern: String, in text: String, fullMatch: Bool) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) else {
            return false
        }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range) else {
            return false
        }
        if fullMatch {
            return match.range.length == range.length
        }
        return true
    }
    
    /// En az 2 satır KEY=VALUE → .env benzeri
    nonisolated private static func isEnvFile(_ text: String) -> Bool {
        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix("#") }
        
        guard lines.count >= 2 else { return false }
        
        guard let regex = try? NSRegularExpression(pattern: envLinePattern, options: [.anchorsMatchLines]) else {
            return false
        }
        
        let matching = lines.filter { line in
            let range = NSRange(line.startIndex..., in: line)
            return regex.firstMatch(in: line, options: [], range: range) != nil
        }
        
        // Satırların çoğunluğu KEY=VALUE ise .env say
        return matching.count >= 2 && Double(matching.count) / Double(lines.count) >= 0.6
    }
    
    nonisolated private static func containsValidCreditCard(_ text: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: cardDigitPattern, options: []) else {
            return false
        }
        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, options: [], range: range)
        
        for match in matches {
            guard let swiftRange = Range(match.range, in: text) else { continue }
            let digits = text[swiftRange].filter(\.isNumber)
            guard (13...19).contains(digits.count), passesLuhn(digits) else { continue }
            return true
        }
        return false
    }
    
    /// Luhn checksum doğrulaması
    nonisolated static func passesLuhn(_ digits: String) -> Bool {
        let nums = digits.compactMap { Int(String($0)) }
        guard nums.count >= 13 else { return false }
        
        var sum = 0
        let reversed = Array(nums.reversed())
        for (index, digit) in reversed.enumerated() {
            if index % 2 == 1 {
                let doubled = digit * 2
                sum += doubled > 9 ? doubled - 9 : doubled
            } else {
                sum += digit
            }
        }
        return sum % 10 == 0
    }
}
