import Foundation


enum SensitiveKind: String, Equatable, Sendable, Codable {
    case jwt
    case apiKey
    case envFile
    case creditCard
    case passwordManager
}


enum ClipboardContentKind: Equatable, Sendable, Codable {
    case plain
    case url
    case json
    case base64
    case urlEncoded
    case hexColor(hex: String)
    case jwtToken(header: String, payload: String)
    case curlCommand
    case unixTimestamp(dateString: String)
}


enum HistoryFilter: String, CaseIterable, Identifiable, Sendable {
    case all
    case pinned
    case links
    case dev
    case secrets

    var id: String { rawValue }
}


struct ClipboardItem: Identifiable, Equatable, Codable, Sendable {
    let id: UUID
    let text: String
    let date: Date
    var wasURLCleaned: Bool
    var isSensitive: Bool
    var sensitiveKind: SensitiveKind?
    var expiresAt: Date?
    var contentKind: ClipboardContentKind
    var isRevealed: Bool
    var isPinned: Bool

    init(
        id: UUID = UUID(),
        text: String,
        date: Date = Date(),
        wasURLCleaned: Bool = false,
        isSensitive: Bool = false,
        sensitiveKind: SensitiveKind? = nil,
        expiresAt: Date? = nil,
        contentKind: ClipboardContentKind = .plain,
        isRevealed: Bool = false,
        isPinned: Bool = false
    ) {
        self.id = id
        self.text = text
        self.date = date
        self.wasURLCleaned = wasURLCleaned
        self.isSensitive = isSensitive
        self.sensitiveKind = sensitiveKind
        self.expiresAt = expiresAt
        self.contentKind = contentKind
        self.isRevealed = isRevealed
        self.isPinned = isPinned
    }


    var displayText: String {
        if isSensitive && !isRevealed {
            return String(repeating: "•", count: min(max(text.count, 8), 24))
        }
        return text
    }


    var isDevContent: Bool {
        switch contentKind {
        case .json, .base64, .urlEncoded, .hexColor, .jwtToken, .curlCommand, .unixTimestamp:
            return true
        case .url, .plain:
            return false
        }
    }

    var isLinkContent: Bool {
        if case .url = contentKind { return true }
        return wasURLCleaned
    }
}
