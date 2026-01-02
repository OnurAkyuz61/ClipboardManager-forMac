//
//  LocalizationHelper.swift
//  Clipboard Manager
//
//  Created by Onur Akyüz on 25.12.2025.
//

import Foundation

/// Sistem diline göre lokalizasyon sağlayan yardımcı sınıf
class LocalizationHelper {
    /// Sistem dilinin Türkçe olup olmadığını kontrol eder
    static var isTurkish: Bool {
        let preferredLanguage = Locale.preferredLanguages.first ?? ""
        return preferredLanguage.hasPrefix("tr")
    }
    
    /// Lokalize edilmiş string'leri döndürür
    struct Strings {
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
    }
}

