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
    
    /// 1Password / Bitwarden / Keychain — gizli pano işareti
    private static let concealedType = NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType")
    /// Geçici (transient) pano işareti
    private static let transientType = NSPasteboard.PasteboardType("org.nspasteboard.TransientType")
    
    /// Panodan düz metin okur
    static func readString() -> String? {
        pasteboard.string(forType: .string)
    }
    
    /// Metni panoya yalnızca düz metin (`public.utf8-plain-text`) olarak yazar.
    /// Biçimlendirmeyi (RTF/HTML) strip eder — "Düz Metin Olarak Kopyala".
    static func writeString(_ text: String) {
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    /// Sistem panosunu temizler
    static func clear() {
        pasteboard.clearContents()
    }
    
    /// Panonun değişim sayacını döndürür
    static func getChangeCount() -> Int {
        pasteboard.changeCount
    }
    
    /// Password manager / Keychain uyumlu gizli veya geçici pano mı?
    static func isPasteboardConcealed() -> Bool {
        let types = pasteboard.types ?? []
        return types.contains(concealedType) || types.contains(transientType)
    }
}
