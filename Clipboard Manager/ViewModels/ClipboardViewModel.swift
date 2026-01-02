//
//  ClipboardViewModel.swift
//  ClipHistory
//
//  Created by Onur Akyüz on 25.12.2025.
//

import Foundation
import Combine
import AppKit
import ServiceManagement

/// Clipboard yönetimi için ViewModel (MVVM mimarisi)
@MainActor
class ClipboardViewModel: ObservableObject {
    @Published var items: [ClipboardItem] = []
    @Published var launchAtLogin: Bool = false
    
    private var timer: Timer?
    private var lastChangeCount: Int = 0
    private let maxItems = 10
    
    init() {
        // İlk değişim sayacını kaydet
        lastChangeCount = PasteboardHelper.getChangeCount()
        startMonitoring()
        // Otomatik başlatma durumunu kontrol et
        launchAtLogin = isLaunchAtLoginEnabled()
    }
    
    deinit {
        // deinit main actor'da değil, bu yüzden direkt timer'ı invalidate ediyoruz
        timer?.invalidate()
    }
    
    /// Panoyu izlemeye başlar (saniyede 1 kontrol)
    private func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkPasteboard()
            }
        }
    }
    
    /// Panoyu izlemeyi durdurur
    private func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    /// Panodaki değişiklikleri kontrol eder
    private func checkPasteboard() {
        let currentChangeCount = PasteboardHelper.getChangeCount()
        
        // Panoda değişiklik varsa
        if currentChangeCount != lastChangeCount {
            lastChangeCount = currentChangeCount
            
            // Panodan metni oku
            if let text = PasteboardHelper.readString(), !text.isEmpty {
                addItem(text: text)
            }
        }
    }
    
    /// Yeni bir öğe ekler (tekrar kontrolü ve FIFO mantığı ile)
    /// - Parameter text: Eklenecek metin
    private func addItem(text: String) {
        let newItem = ClipboardItem(text: text)
        
        // Aynı metin zaten listede varsa ekleme
        if items.contains(where: { $0.text == text }) {
            return
        }
        
        // FIFO mantığı: En başa ekle
        items.insert(newItem, at: 0)
        
        // Maksimum 10 öğe tut (en eskileri sil)
        if items.count > maxItems {
            items = Array(items.prefix(maxItems))
        }
    }
    
    /// Öğeyi panoya kopyalar
    /// - Parameter item: Kopyalanacak öğe
    func copyToPasteboard(_ item: ClipboardItem) {
        PasteboardHelper.writeString(item.text)
    }
    
    /// Tüm geçmişi temizler
    func clearHistory() {
        items.removeAll()
    }
    
    /// Uygulamadan çıkar
    func quit() {
        NSApplication.shared.terminate(nil)
    }
    
    /// Otomatik başlatmanın aktif olup olmadığını kontrol eder
    private func isLaunchAtLoginEnabled() -> Bool {
        // macOS 13.0+ için ServiceManagement framework kullan
        if #available(macOS 13.0, *) {
            let status = SMAppService.mainApp.status
            return status == .enabled
        } else {
            // macOS 13.0'dan önceki sürümler için eski yöntem (gerekirse)
            return false
        }
    }
    
    /// Otomatik başlatmayı açıp kapatır
    func toggleLaunchAtLogin() {
        if #available(macOS 13.0, *) {
            let service = SMAppService.mainApp
            
            do {
                if launchAtLogin {
                    // Login Items'dan kaldır
                    try service.unregister()
                    launchAtLogin = false
                } else {
                    // Login Items'a ekle
                    try service.register()
                    launchAtLogin = true
                }
            } catch {
                print("Otomatik başlatma ayarı değiştirilemedi: \(error.localizedDescription)")
                // Hata durumunda durumu tekrar kontrol et
                launchAtLogin = isLaunchAtLoginEnabled()
            }
        }
    }
}

