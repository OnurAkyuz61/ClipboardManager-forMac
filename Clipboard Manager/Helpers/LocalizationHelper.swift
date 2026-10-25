//
//  LocalizationHelper.swift
//  Clipboard Manager
//
//  Created by Onur Akyüz on 25.12.2025.
//

import Foundation

/// Sistem diline göre lokalizasyon sağlayan yardımcı sınıf
enum LocalizationHelper {
    /// Sistem dilinin Türkçe olup olmadığını kontrol eder
    static var isTurkish: Bool {
        let preferredLanguage = Locale.preferredLanguages.first ?? ""
        return preferredLanguage.hasPrefix("tr")
    }
    
    /// Lokalize edilmiş string'leri döndürür
    enum Strings {
        static var title: String {
            isTurkish ? "Kopyalama Geçmişi" : "Clipboard History"
        }
        
        static var emptyState: String {
            isTurkish ? "Henüz kopyalanan metin yok" : "No copied text yet"
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
            isTurkish ? "Geliştirici JSON Araçları" : "Show Developer JSON actions"
        }
        
        static var secretTimeout: String {
            isTurkish ? "Silme süresi" : "Clear after"
        }
        
        static var cleanedBadge: String {
            isTurkish ? "✨ Temizlendi" : "✨ Cleaned"
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
        
        static var copyAsSwift: String {
            "Swift Struct"
        }
        
        static var copyAsTypeScript: String {
            "TS Interface"
        }
        
        static var copyAsCSharp: String {
            "C# Class"
        }
        
        static var formatJSON: String {
            isTurkish ? "Formatla" : "Format"
        }
        
        static var minifyJSON: String {
            "Minify"
        }
        
        static var decode: String {
            "Decode"
        }
        
        static var jsonBadge: String {
            "JSON"
        }
        
        static func secondsLabel(_ value: Int) -> String {
            isTurkish ? "\(value) sn" : "\(value)s"
        }
    }
}
