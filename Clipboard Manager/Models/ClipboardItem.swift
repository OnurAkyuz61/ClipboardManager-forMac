//
//  ClipboardItem.swift
//  ClipHistory
//
//  Created by Onur Akyüz on 25.12.2025.
//

import Foundation

/// Hassas veri türü
enum SensitiveKind: String, Equatable, Sendable {
    case jwt
    case apiKey
    case envFile
    case creditCard
}

/// Panodaki içeriğin algılanan türü
enum ClipboardContentKind: Equatable, Sendable {
    case plain
    case url
    case json
    case base64
    case urlEncoded
    case hexColor(hex: String)
}

/// Panodan kopyalanan bir metin öğesini temsil eden model
struct ClipboardItem: Identifiable, Equatable {
    let id: UUID
    let text: String
    let date: Date
    var wasURLCleaned: Bool
    var isSensitive: Bool
    var sensitiveKind: SensitiveKind?
    var expiresAt: Date?
    var contentKind: ClipboardContentKind
    var isRevealed: Bool
    
    init(
        text: String,
        wasURLCleaned: Bool = false,
        isSensitive: Bool = false,
        sensitiveKind: SensitiveKind? = nil,
        expiresAt: Date? = nil,
        contentKind: ClipboardContentKind = .plain,
        isRevealed: Bool = false
    ) {
        self.id = UUID()
        self.text = text
        self.date = Date()
        self.wasURLCleaned = wasURLCleaned
        self.isSensitive = isSensitive
        self.sensitiveKind = sensitiveKind
        self.expiresAt = expiresAt
        self.contentKind = contentKind
        self.isRevealed = isRevealed
    }
    
    /// Aynı metin içeriğine sahip olup olmadığını kontrol eder
    static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        lhs.text == rhs.text
    }
    
    /// UI'da gösterilecek metin (hassas ise maskeli)
    var displayText: String {
        if isSensitive && !isRevealed {
            return String(repeating: "•", count: min(max(text.count, 8), 24))
        }
        return text
    }
}
