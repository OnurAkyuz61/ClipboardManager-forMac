//
//  LocalizationHelper.swift
//  Clipboard Manager
//
//  Created by Onur Akyüz on 25.12.2025.
//

import Foundation

/// Sistem diline göre lokalizasyon sağlayan yardımcı sınıf
enum LocalizationHelper {
    static var isTurkish: Bool {
        let preferredLanguage = Locale.preferredLanguages.first ?? ""
        return preferredLanguage.hasPrefix("tr")
    }
    
    enum Strings {
        static var title: String {
            isTurkish ? "Kopyalama Geçmişi" : "Clipboard History"
        }
        
        static var emptyState: String {
            isTurkish ? "Henüz kopyalanan metin yok" : "No copied text yet"
        }
        
        static var emptyFilter: String {
            isTurkish ? "Bu filtrede sonuç yok" : "No results for this filter"
        }
        
        static var clearHistory: String {
            isTurkish ? "Geçmişi Temizle" : "Clear History"
        }
        
        static var quit: String {
            isTurkish ? "Çıkış" : "Quit"
        }
        
        static var launchAtLogin: String {
            isTurkish ? "Otomatik Başlat" : "Launch at Login"
        }
        
        static var smartRules: String {
            isTurkish ? "Akıllı Kurallar" : "Smart Rules"
        }
        
        static var autoCleanURLs: String {
            isTurkish ? "Otomatik URL Temizleme" : "Auto-clean tracking URLs"
        }
        
        static var autoClearSecrets: String {
            isTurkish ? "Hassas Veri Otomatik Silici" : "Auto-clear secrets"
        }
        
        static var showDevTools: String {
            isTurkish ? "Geliştirici JSON Araçları" : "Show Developer tools"
        }
        
        static var secretTimeout: String {
            isTurkish ? "Silme süresi" : "Clear after"
        }
        
        static var maxHistory: String {
            isTurkish ? "Maks. geçmiş" : "Max history"
        }
        
        static var searchPlaceholder: String {
            isTurkish ? "Geçmişte ara…" : "Search history…"
        }
        
        static var cleanedBadge: String {
            isTurkish ? "✨ Temizlendi" : "✨ Cleaned"
        }
        
        static var copiedBadge: String {
            isTurkish ? "✅ Kopyalandı!" : "✅ Copied!"
        }
        
        static func expiresIn(_ seconds: Int) -> String {
            isTurkish ? "🛡️ \(seconds)s sonra silinecek" : "🛡️ Deletes in \(seconds)s"
        }
        
        static var reveal: String {
            isTurkish ? "Göster" : "Reveal"
        }
        
        static var hide: String {
            isTurkish ? "Gizle" : "Hide"
        }
        
        static var pin: String {
            isTurkish ? "Sabitle" : "Pin"
        }
        
        static var unpin: String {
            isTurkish ? "Sabiti Kaldır" : "Unpin"
        }
        
        static var delete: String {
            isTurkish ? "Sil" : "Delete"
        }
        
        static var copy: String {
            isTurkish ? "Kopyala" : "Copy"
        }
        
        static var copyAsSwift: String { "Swift Struct" }
        static var copyAsTypeScript: String { "TS Interface" }
        static var copyAsCSharp: String { "C# Class" }
        
        static var formatJSON: String {
            isTurkish ? "Formatla" : "Format"
        }
        
        static var minifyJSON: String { "Minify" }
        static var decode: String { "Decode" }
        static var jsonBadge: String { "JSON" }
        static var jwtBadge: String { "JWT" }
        static var curlBadge: String { "cURL" }
        
        static var copyJWTPayload: String {
            isTurkish ? "Decoded Payload" : "Copy Decoded Payload"
        }
        
        static var copySwiftURLRequest: String {
            "Swift URLRequest"
        }
        
        static var copyJSFetch: String {
            "JS fetch()"
        }
        
        static var copyISO8601: String {
            "ISO 8601"
        }
        
        static var camelCase: String { "camelCase" }
        static var snakeCase: String { "snake_case" }
        static var kebabCase: String { "kebab-case" }
        static var upperCase: String { "UPPER_CASE" }
        
        static func secondsLabel(_ value: Int) -> String {
            isTurkish ? "\(value) sn" : "\(value)s"
        }
        
        static func filterTitle(_ filter: HistoryFilter) -> String {
            switch filter {
            case .all:
                return isTurkish ? "Tümü" : "All"
            case .pinned:
                return isTurkish ? "📌 Pinli" : "📌 Pinned"
            case .links:
                return isTurkish ? "🔗 Link" : "🔗 Links"
            case .dev:
                return isTurkish ? "🛠️ Dev" : "🛠️ Dev"
            case .secrets:
                return isTurkish ? "🛡️ Gizli" : "🛡️ Secrets"
            }
        }
    }
}
