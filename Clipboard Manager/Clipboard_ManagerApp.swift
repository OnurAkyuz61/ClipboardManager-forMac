import SwiftUI
import AppKit

@main
struct ClipHistoryApp: App {
    @StateObject private var viewModel = ClipboardViewModel()

    init() {

        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {

        MenuBarExtra(LocalizationHelper.Strings.title, systemImage: "doc.on.clipboard") {
            MenuBarList(viewModel: viewModel)
        }
        .menuBarExtraStyle(.window)
    }
}
