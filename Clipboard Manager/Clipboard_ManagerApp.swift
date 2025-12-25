//
//  ClipHistoryApp.swift
//  ClipHistory
//
//  Created by Onur Akyüz on 25.12.2025.
//

import SwiftUI
import AppKit

@main
struct ClipHistoryApp: App {
    @StateObject private var viewModel = ClipboardViewModel()
    
    init() {
        // Uygulamanın Dock'ta ve Cmd+Tab'da görünmemesini sağlar
        NSApplication.shared.setActivationPolicy(.accessory)
    }
    
    var body: some Scene {
        // MenuBarExtra kullanarak sadece menü çubuğunda görünür
        MenuBarExtra(LocalizationHelper.Strings.title, systemImage: "doc.on.clipboard") {
            MenuBarList(viewModel: viewModel)
        }
        .menuBarExtraStyle(.window)
    }
}
