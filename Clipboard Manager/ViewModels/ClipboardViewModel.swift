import Foundation
import Combine
import AppKit
import ServiceManagement


@MainActor
final class ClipboardViewModel: ObservableObject {
    @Published var items: [ClipboardItem] = []
    @Published var launchAtLogin: Bool = false
    @Published var searchText: String = ""
    @Published var selectedFilter: HistoryFilter = .all
    @Published var lastCopiedItemId: UUID?


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
    @Published var maxItems: Int {
        didSet {
            UserDefaults.standard.set(maxItems, forKey: Keys.maxItems)
            enforceLimitsAndPersist()
        }
    }

    private enum Keys {
        static let autoCleanURLs = "smart.autoCleanURLs"
        static let autoClearSecrets = "smart.autoClearSecrets"
        static let showDevTools = "smart.showDevTools"
        static let secretClearSeconds = "smart.secretClearSeconds"
        static let maxItems = "smart.maxItems"
    }

    private var timer: Timer?
    private var lastChangeCount: Int = 0
    private var ignoreNextPasteboardChange = false
    private var isProcessing = false
    private var copiedResetTask: Task<Void, Never>?


    var filteredItems: [ClipboardItem] {
        var result = items

        switch selectedFilter {
        case .all:
            break
        case .pinned:
            result = result.filter(\.isPinned)
        case .links:
            result = result.filter(\.isLinkContent)
        case .dev:
            result = result.filter(\.isDevContent)
        case .secrets:
            result = result.filter(\.isSensitive)
        }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty {
            result = result.filter { $0.text.localizedCaseInsensitiveContains(query) }
        }

        return result
    }

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
        if defaults.object(forKey: Keys.maxItems) == nil {
            defaults.set(30, forKey: Keys.maxItems)
        }

        self.autoCleanURLs = defaults.bool(forKey: Keys.autoCleanURLs)
        self.autoClearSecrets = defaults.bool(forKey: Keys.autoClearSecrets)
        self.showDevTools = defaults.bool(forKey: Keys.showDevTools)
        let storedTimeout = defaults.integer(forKey: Keys.secretClearSeconds)
        self.secretClearSeconds = storedTimeout > 0 ? storedTimeout : 60
        let storedMax = defaults.integer(forKey: Keys.maxItems)
        self.maxItems = [15, 30, 50].contains(storedMax) ? storedMax : 30

        loadPersistedHistory()

        lastChangeCount = PasteboardHelper.getChangeCount()
        startMonitoring()
        launchAtLogin = isLaunchAtLoginEnabled()
    }

    deinit {
        timer?.invalidate()
    }


    private func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }
    }

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

        let concealed = PasteboardHelper.isPasteboardConcealed()

        isProcessing = true
        Task { @MainActor in
            await processNewClipboardText(text, isConcealed: concealed)
            isProcessing = false
        }
    }


    private func processNewClipboardText(_ raw: String, isConcealed: Bool) async {
        let source = raw
        let shouldCleanURLs = autoCleanURLs
        let shouldShield = autoClearSecrets
        let timeout = secretClearSeconds

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

            let sensitive = PrivacyShield.detect(working)
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

        switch analysis.kind {
        case .jwtToken, .curlCommand, .unixTimestamp, .json, .hexColor:
            contentKind = analysis.kind
        case .base64, .urlEncoded:
            if !analysis.wasCleaned { contentKind = analysis.kind }
        case .url, .plain:
            break
        }


        var sensitiveKind: SensitiveKind? = shouldShield ? analysis.sensitive : nil
        if case .jwtToken = contentKind, shouldShield, sensitiveKind == nil {
            sensitiveKind = .jwt
        }
        if isConcealed {
            sensitiveKind = sensitiveKind ?? .passwordManager
        }

        let isSensitive = sensitiveKind != nil
        let expiresAt: Date? = isSensitive
            ? Date().addingTimeInterval(TimeInterval(timeout))
            : nil

        addItem(
            text: analysis.text,
            wasURLCleaned: analysis.wasCleaned,
            isSensitive: isSensitive,
            sensitiveKind: sensitiveKind,
            expiresAt: expiresAt,
            contentKind: contentKind
        )
    }

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
            insertSorted(existing)
            enforceLimitsAndPersist()
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

        insertSorted(newItem)
        enforceLimitsAndPersist()
    }


    private func insertSorted(_ item: ClipboardItem) {
        items.insert(item, at: 0)
        reorderPinnedFirst()
    }

    private func reorderPinnedFirst() {
        let pinned = items.filter(\.isPinned)
        let unpinned = items.filter { !$0.isPinned }
        items = pinned + unpinned
    }

    private func enforceLimitsAndPersist() {
        reorderPinnedFirst()
        let pinned = items.filter(\.isPinned)
        var unpinned = items.filter { !$0.isPinned }
        if unpinned.count > maxItems {
            unpinned = Array(unpinned.prefix(maxItems))
        }
        items = pinned + unpinned
        persistHistory()
    }


    private func purgeExpiredSecrets() {
        let now = Date()
        let expired = items.filter { item in
            guard item.isSensitive, let expiresAt = item.expiresAt else { return false }
            return expiresAt <= now
        }
        guard !expired.isEmpty else { return }

        let expiredIds = Set(expired.map(\.id))
        let expiredTexts = Set(expired.map(\.text))
        items.removeAll { expiredIds.contains($0.id) }

        if let current = PasteboardHelper.readString(), expiredTexts.contains(current) {
            ignoreNextPasteboardChange = true
            PasteboardHelper.clear()
            lastChangeCount = PasteboardHelper.getChangeCount()
        }

        persistHistory()
    }


    func copyToPasteboard(_ item: ClipboardItem) {
        writeInternally(item.text)
        markCopied(item.id)
    }

    func copyText(_ text: String, feedbackFor itemId: UUID? = nil) {
        writeInternally(text)
        if let itemId {
            markCopied(itemId)
        }
    }

    private func markCopied(_ id: UUID) {
        lastCopiedItemId = id
        copiedResetTask?.cancel()
        copiedResetTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            guard !Task.isCancelled else { return }
            if lastCopiedItemId == id {
                lastCopiedItemId = nil
            }
        }
    }

    func toggleReveal(for item: ClipboardItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].isRevealed.toggle()
    }

    func togglePin(for item: ClipboardItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].isPinned.toggle()
        enforceLimitsAndPersist()
    }


    func clearHistory() {
        items.removeAll { !$0.isPinned }
        persistHistory()
    }

    func removeItem(_ item: ClipboardItem) {
        items.removeAll { $0.id == item.id }
        if PasteboardHelper.readString() == item.text {
            ignoreNextPasteboardChange = true
            PasteboardHelper.clear()
            lastChangeCount = PasteboardHelper.getChangeCount()
        }
        persistHistory()
    }


    func copySwiftStruct(from item: ClipboardItem) {
        Task {
            let code = await Task.detached { DevConverter.toSwiftStruct(item.text) }.value
            if let code { copyText(code, feedbackFor: item.id) }
        }
    }

    func copyTypeScript(from item: ClipboardItem) {
        Task {
            let code = await Task.detached { DevConverter.toTypeScriptInterface(item.text) }.value
            if let code { copyText(code, feedbackFor: item.id) }
        }
    }

    func copyCSharp(from item: ClipboardItem) {
        Task {
            let code = await Task.detached { DevConverter.toCSharpClass(item.text) }.value
            if let code { copyText(code, feedbackFor: item.id) }
        }
    }

    func formatJSON(from item: ClipboardItem) {
        Task {
            let pretty = await Task.detached { DevConverter.prettyJSON(item.text) }.value
            if let pretty { copyText(pretty, feedbackFor: item.id) }
        }
    }

    func minifyJSON(from item: ClipboardItem) {
        Task {
            let mini = await Task.detached { DevConverter.minifyJSON(item.text) }.value
            if let mini { copyText(mini, feedbackFor: item.id) }
        }
    }

    func decodeBase64(from item: ClipboardItem) {
        Task {
            let decoded = await Task.detached { DevConverter.decodeBase64(item.text) }.value
            if let decoded { copyText(decoded, feedbackFor: item.id) }
        }
    }

    func decodeURL(from item: ClipboardItem) {
        Task {
            let decoded = await Task.detached { DevConverter.decodeURLEncoded(item.text) }.value
            if let decoded { copyText(decoded, feedbackFor: item.id) }
        }
    }

    func copyJWTPayload(from item: ClipboardItem) {
        Task {
            let payload = await Task.detached { () -> String? in
                if case .jwtToken(_, let payload) = item.contentKind {
                    return payload
                }
                return DevConverter.decodeJWT(item.text)?.payload
            }.value
            if let payload { copyText(payload, feedbackFor: item.id) }
        }
    }

    func copyCurlAsSwift(from item: ClipboardItem) {
        Task {
            let code = await Task.detached { DevConverter.curlToSwiftURLRequest(item.text) }.value
            if let code { copyText(code, feedbackFor: item.id) }
        }
    }

    func copyCurlAsJSFetch(from item: ClipboardItem) {
        Task {
            let code = await Task.detached { DevConverter.curlToJSFetch(item.text) }.value
            if let code { copyText(code, feedbackFor: item.id) }
        }
    }

    func copyTimestampISO(from item: ClipboardItem) {
        Task {
            let iso = await Task.detached { DevConverter.unixTimestampToISO8601(item.text) }.value
            if let iso { copyText(iso, feedbackFor: item.id) }
        }
    }

    func copyCamelCase(from item: ClipboardItem) {
        copyText(DevConverter.toCamelCase(item.text), feedbackFor: item.id)
    }

    func copySnakeCase(from item: ClipboardItem) {
        copyText(DevConverter.toSnakeCase(item.text), feedbackFor: item.id)
    }

    func copyKebabCase(from item: ClipboardItem) {
        copyText(DevConverter.toKebabCase(item.text), feedbackFor: item.id)
    }

    func copyUpperSnakeCase(from item: ClipboardItem) {
        copyText(DevConverter.toUpperSnakeCase(item.text), feedbackFor: item.id)
    }

    func quit() {
        NSApplication.shared.terminate(nil)
    }


    private var historyFileURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("ClipboardManager", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir.appendingPathComponent("clipboard_history.json")
    }

    private func persistHistory() {

        let safeItems = items.filter { !$0.isSensitive }
        do {
            let data = try JSONEncoder().encode(safeItems)
            try data.write(to: historyFileURL, options: [.atomic])
        } catch {
            print("Geçmiş kaydedilemedi: \(error.localizedDescription)")
        }
    }

    private func loadPersistedHistory() {
        let url = historyFileURL
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            let data = try Data(contentsOf: url)
            let loaded = try JSONDecoder().decode([ClipboardItem].self, from: data)

            items = loaded.filter { !$0.isSensitive }
            reorderPinnedFirst()
        } catch {
            print("Geçmiş yüklenemedi: \(error.localizedDescription)")
        }
    }


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
