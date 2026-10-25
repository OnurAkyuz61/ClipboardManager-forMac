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
final class ClipboardViewModel: ObservableObject {
    @Published var items: [ClipboardItem] = []
    @Published var launchAtLogin: Bool = false
    
    // MARK: - Smart Rules (UserDefaults)
    
    @Published var autoCleanURLs: Bool {
        didSet { UserDefaults.standard.set(autoCleanURLs, forKey: Keys.autoCleanURLs) }
    }
    @Published var autoClearSecrets: Bool {
        didSet { UserDefaults.standard.set(autoClearSecrets, forKey: Keys.autoClearSecrets) }
    }
    @Published var showDevTools: Bool {
        didSet { UserDefaults.standard.set(showDevTools, forKey: Keys.showDevTools) }
    }
    @Published var secretClearSeconds: Int {
        didSet { UserDefaults.standard.set(secretClearSeconds, forKey: Keys.secretClearSeconds) }
    }
    
    private enum Keys {
        static let autoCleanURLs = "smart.autoCleanURLs"
        static let autoClearSecrets = "smart.autoClearSecrets"
        static let showDevTools = "smart.showDevTools"
        static let secretClearSeconds = "smart.secretClearSeconds"
    }
    
    private var timer: Timer?
    private var lastChangeCount: Int = 0
    private let maxItems = 10
    
    /// Kendi yazdığımız pano değişikliklerini yok saymak için (infinite loop önleme)
    private var ignoreNextPasteboardChange = false
    
    /// İşlenmekte olan metin — yarış durumlarını azaltır
    private var isProcessing = false
    
    init() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: Keys.autoCleanURLs) == nil {
            defaults.set(true, forKey: Keys.autoCleanURLs)
        }
        if defaults.object(forKey: Keys.autoClearSecrets) == nil {
            defaults.set(true, forKey: Keys.autoClearSecrets)
        }
        if defaults.object(forKey: Keys.showDevTools) == nil {
            defaults.set(true, forKey: Keys.showDevTools)
        }
        if defaults.object(forKey: Keys.secretClearSeconds) == nil {
            defaults.set(60, forKey: Keys.secretClearSeconds)
        }
        
        self.autoCleanURLs = defaults.bool(forKey: Keys.autoCleanURLs)
        self.autoClearSecrets = defaults.bool(forKey: Keys.autoClearSecrets)
        self.showDevTools = defaults.bool(forKey: Keys.showDevTools)
        let storedTimeout = defaults.integer(forKey: Keys.secretClearSeconds)
        self.secretClearSeconds = storedTimeout > 0 ? storedTimeout : 60
        
        lastChangeCount = PasteboardHelper.getChangeCount()
        startMonitoring()
        launchAtLogin = isLaunchAtLoginEnabled()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    // MARK: - Monitoring
    
    private func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }
    }
    
    /// Her saniye: pano kontrolü + süresi dolan hassas öğeleri temizle
    private func tick() {
        purgeExpiredSecrets()
        checkPasteboard()
    }
    
    private func checkPasteboard() {
        let currentChangeCount = PasteboardHelper.getChangeCount()
        guard currentChangeCount != lastChangeCount else { return }
        
        lastChangeCount = currentChangeCount
        
        if ignoreNextPasteboardChange {
            ignoreNextPasteboardChange = false
            return
        }
        
        guard !isProcessing else { return }
        guard let text = PasteboardHelper.readString(), !text.isEmpty else { return }
        
        isProcessing = true
        Task { @MainActor in
            await processNewClipboardText(text)
            isProcessing = false
        }
    }
    
    // MARK: - Smart processing pipeline
    
    private func processNewClipboardText(_ raw: String) async {
        let source = raw
        let shouldCleanURLs = autoCleanURLs
        let shouldShield = autoClearSecrets
        let timeout = secretClearSeconds
        
        // Ağır analizleri arka planda çalıştır (UI thread bloklanmaz)
        let analysis = await Task.detached(priority: .userInitiated) { () -> (
            text: String,
            wasCleaned: Bool,
            sensitive: SensitiveKind?,
            kind: ClipboardContentKind
        ) in
            var working = source
            var wasCleaned = false
            
            if shouldCleanURLs, let result = URLSanitizer.sanitize(source), result.didClean {
                working = result.cleaned
                wasCleaned = true
            }
            
            let sensitive = shouldShield ? PrivacyShield.detect(working) : nil
            let kind = DevConverter.detectContentKind(working)
            return (working, wasCleaned, sensitive, kind)
        }.value
        
        var contentKind = analysis.kind
        
        if analysis.wasCleaned {
            writeInternally(analysis.text)
            contentKind = .url
        } else if shouldCleanURLs, URLSanitizer.sanitize(source) != nil {
            contentKind = .url
        }
        
        if case .json = analysis.kind {
            contentKind = .json
        } else if case .hexColor = analysis.kind {
            contentKind = analysis.kind
        } else if case .base64 = analysis.kind, !analysis.wasCleaned {
            contentKind = .base64
        } else if case .urlEncoded = analysis.kind, !analysis.wasCleaned {
            contentKind = .urlEncoded
        }
        
        let expiresAt: Date? = analysis.sensitive.map { _ in
            Date().addingTimeInterval(TimeInterval(timeout))
        }
        
        addItem(
            text: analysis.text,
            wasURLCleaned: analysis.wasCleaned,
            isSensitive: analysis.sensitive != nil,
            sensitiveKind: analysis.sensitive,
            expiresAt: expiresAt,
            contentKind: contentKind
        )
    }
    
    /// Sistem panosuna yazar ve bir sonraki changeCount'u yok sayar
    private func writeInternally(_ text: String) {
        ignoreNextPasteboardChange = true
        PasteboardHelper.writeString(text)
        lastChangeCount = PasteboardHelper.getChangeCount()
    }
    
    private func addItem(
        text: String,
        wasURLCleaned: Bool,
        isSensitive: Bool,
        sensitiveKind: SensitiveKind?,
        expiresAt: Date?,
        contentKind: ClipboardContentKind
    ) {
        if items.contains(where: { $0.text == text }) {
            // Aynı metin varsa metadata'yı güncelle (yeniden kopyalama)
            if let index = items.firstIndex(where: { $0.text == text }) {
                var existing = items[index]
                existing.wasURLCleaned = existing.wasURLCleaned || wasURLCleaned
                if isSensitive {
                    existing.isSensitive = true
                    existing.sensitiveKind = sensitiveKind
                    existing.expiresAt = expiresAt
                    existing.isRevealed = false
                }
                existing.contentKind = contentKind
                items.remove(at: index)
                items.insert(existing, at: 0)
            }
            return
        }
        
        let newItem = ClipboardItem(
            text: text,
            wasURLCleaned: wasURLCleaned,
            isSensitive: isSensitive,
            sensitiveKind: sensitiveKind,
            expiresAt: expiresAt,
            contentKind: contentKind
        )
        
        items.insert(newItem, at: 0)
        
        if items.count > maxItems {
            items = Array(items.prefix(maxItems))
        }
    }
    
    // MARK: - Secret expiry
    
    private func purgeExpiredSecrets() {
        let now = Date()
        let expired = items.filter { item in
            guard item.isSensitive, let expiresAt = item.expiresAt else { return false }
            return expiresAt <= now
        }
        guard !expired.isEmpty else { return }
        
        let expiredTexts = Set(expired.map(\.text))
        items.removeAll { expiredTexts.contains($0.text) }
        
        if let current = PasteboardHelper.readString(), expiredTexts.contains(current) {
            ignoreNextPasteboardChange = true
            PasteboardHelper.clear()
            lastChangeCount = PasteboardHelper.getChangeCount()
        }
    }
    
    // MARK: - User actions
    
    func copyToPasteboard(_ item: ClipboardItem) {
        writeInternally(item.text)
    }
    
    func toggleReveal(for item: ClipboardItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].isRevealed.toggle()
    }
    
    func clearHistory() {
        items.removeAll()
    }
    
    func removeItem(_ item: ClipboardItem) {
        items.removeAll { $0.id == item.id }
        if PasteboardHelper.readString() == item.text {
            ignoreNextPasteboardChange = true
            PasteboardHelper.clear()
            lastChangeCount = PasteboardHelper.getChangeCount()
        }
    }
    
    // MARK: - Dev converter actions
    
    func copySwiftStruct(from item: ClipboardItem) {
        Task {
            let code = await Task.detached { DevConverter.toSwiftStruct(item.text) }.value
            if let code { writeInternally(code) }
        }
    }
    
    func copyTypeScript(from item: ClipboardItem) {
        Task {
            let code = await Task.detached { DevConverter.toTypeScriptInterface(item.text) }.value
            if let code { writeInternally(code) }
        }
    }
    
    func copyCSharp(from item: ClipboardItem) {
        Task {
            let code = await Task.detached { DevConverter.toCSharpClass(item.text) }.value
            if let code { writeInternally(code) }
        }
    }
    
    func formatJSON(from item: ClipboardItem) {
        Task {
            let pretty = await Task.detached { DevConverter.prettyJSON(item.text) }.value
            if let pretty { writeInternally(pretty) }
        }
    }
    
    func minifyJSON(from item: ClipboardItem) {
        Task {
            let mini = await Task.detached { DevConverter.minifyJSON(item.text) }.value
            if let mini { writeInternally(mini) }
        }
    }
    
    func decodeBase64(from item: ClipboardItem) {
        Task {
            let decoded = await Task.detached { DevConverter.decodeBase64(item.text) }.value
            if let decoded { writeInternally(decoded) }
        }
    }
    
    func decodeURL(from item: ClipboardItem) {
        Task {
            let decoded = await Task.detached { DevConverter.decodeURLEncoded(item.text) }.value
            if let decoded { writeInternally(decoded) }
        }
    }
    
    func quit() {
        NSApplication.shared.terminate(nil)
    }
    
    // MARK: - Launch at Login
    
    private func isLaunchAtLoginEnabled() -> Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        }
        return false
    }
    
    func toggleLaunchAtLogin() {
        if #available(macOS 13.0, *) {
            let service = SMAppService.mainApp
            do {
                if launchAtLogin {
                    try service.unregister()
                    launchAtLogin = false
                } else {
                    try service.register()
                    launchAtLogin = true
                }
            } catch {
                print("Otomatik başlatma ayarı değiştirilemedi: \(error.localizedDescription)")
                launchAtLogin = isLaunchAtLoginEnabled()
            }
        }
    }
}
