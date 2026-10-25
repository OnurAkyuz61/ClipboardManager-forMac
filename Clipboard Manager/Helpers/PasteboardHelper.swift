//
//  PasteboardHelper.swift
//  ClipHistory
//
//  Created by Onur Akyüz on 25.12.2025.
//

import AppKit

/// NSPasteboard işlemleri için yardımcı sınıf
enum PasteboardHelper {
    private static let pasteboard = NSPasteboard.general
    
    /// Panodan metin okur
    /// - Returns: Panodaki metin, yoksa nil
    static func readString() -> String? {
        pasteboard.string(forType: .string)
    }
    
    /// Metni panoya yazar
    /// - Parameter text: Panoya yazılacak metin
    static func writeString(_ text: String) {
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    /// Sistem panosunu temizler
    static func clear() {
        pasteboard.clearContents()
    }
    
    /// Panonun değişim sayacını döndürür (değişiklik kontrolü için)
    /// - Returns: Panonun changeCount değeri
    static func getChangeCount() -> Int {
        pasteboard.changeCount
    }
}
