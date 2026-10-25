//
//  MenuBarList.swift
//  ClipHistory
//
//  Created by Onur Akyüz on 25.12.2025.
//

import SwiftUI
import AppKit

/// Menü çubuğunda gösterilecek ana liste görünümü
struct MenuBarList: View {
    @ObservedObject var viewModel: ClipboardViewModel
    @State private var showSmartRules = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Başlık
            HStack {
                Text(LocalizationHelper.Strings.title)
                    .font(.headline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                Spacer()
            }
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Liste
            if viewModel.items.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text(LocalizationHelper.Strings.emptyState)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(viewModel.items) { item in
                            ClipboardItemRow(item: item, viewModel: viewModel)
                        }
                    }
                }
                .frame(maxHeight: 420)
            }
            
            Divider()
            
            // Alt butonlar + Smart Rules
            VStack(spacing: 0) {
                Button {
                    viewModel.clearHistory()
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text(LocalizationHelper.Strings.clearHistory)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.items.isEmpty)
                
                Divider()
                
                // Smart Rules
                DisclosureGroup(isExpanded: $showSmartRules) {
                    SmartRulesPanel(viewModel: viewModel)
                        .padding(.horizontal, 8)
                        .padding(.bottom, 8)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "wand.and.stars")
                        Text(LocalizationHelper.Strings.smartRules)
                            .font(.system(size: 13, weight: .medium))
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 4)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                
                Divider()
                
                Button {
                    viewModel.toggleLaunchAtLogin()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: viewModel.launchAtLogin ? "checkmark.square.fill" : "square")
                            .foregroundColor(viewModel.launchAtLogin ? .blue : .secondary)
                        Text(LocalizationHelper.Strings.launchAtLogin)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                
                Divider()
                
                Button {
                    viewModel.quit()
                } label: {
                    HStack {
                        Image(systemName: "power")
                        Text(LocalizationHelper.Strings.quit)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(width: 360)
    }
}

// MARK: - Smart Rules

struct SmartRulesPanel: View {
    @ObservedObject var viewModel: ClipboardViewModel
    
    private let timeoutOptions = [30, 60, 120, 300]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: $viewModel.autoCleanURLs) {
                Text(LocalizationHelper.Strings.autoCleanURLs)
                    .font(.system(size: 12))
            }
            .toggleStyle(.checkbox)
            
            Toggle(isOn: $viewModel.autoClearSecrets) {
                Text(LocalizationHelper.Strings.autoClearSecrets)
                    .font(.system(size: 12))
            }
            .toggleStyle(.checkbox)
            
            if viewModel.autoClearSecrets {
                HStack {
                    Text(LocalizationHelper.Strings.secretTimeout)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Spacer()
                    Picker("", selection: $viewModel.secretClearSeconds) {
                        ForEach(timeoutOptions, id: \.self) { value in
                            Text(LocalizationHelper.Strings.secondsLabel(value)).tag(value)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 90)
                }
                .padding(.leading, 20)
            }
            
            Toggle(isOn: $viewModel.showDevTools) {
                Text(LocalizationHelper.Strings.showDevTools)
                    .font(.system(size: 12))
            }
            .toggleStyle(.checkbox)
        }
        .padding(.top, 4)
    }
}

// MARK: - Item row

struct ClipboardItemRow: View {
    let item: ClipboardItem
    @ObservedObject var viewModel: ClipboardViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 6) {
                Button {
                    if item.isSensitive && !item.isRevealed {
                        viewModel.toggleReveal(for: item)
                    } else {
                        viewModel.copyToPasteboard(item)
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .top, spacing: 6) {
                            if case .hexColor(let hex) = item.contentKind,
                               let nsColor = DevConverter.nsColor(fromHex: hex) {
                                Circle()
                                    .fill(Color(nsColor))
                                    .frame(width: 12, height: 12)
                                    .overlay(Circle().stroke(Color.secondary.opacity(0.4), lineWidth: 0.5))
                                    .padding(.top, 2)
                            }
                            
                            Text(item.displayText)
                                .font(.system(size: 13, design: item.isSensitive && !item.isRevealed ? .monospaced : .default))
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                                .foregroundColor(.primary)
                            
                            Spacer(minLength: 0)
                        }
                        
                        HStack(spacing: 6) {
                            if item.wasURLCleaned {
                                BadgeView(text: LocalizationHelper.Strings.cleanedBadge, color: .green)
                            }
                            
                            if case .json = item.contentKind {
                                BadgeView(text: LocalizationHelper.Strings.jsonBadge, color: .orange)
                            }
                            
                            if item.isSensitive, let expiresAt = item.expiresAt {
                                TimelineView(.periodic(from: .now, by: 1)) { context in
                                    let remaining = max(0, Int(expiresAt.timeIntervalSince(context.date)))
                                    BadgeView(
                                        text: LocalizationHelper.Strings.expiresIn(remaining),
                                        color: remaining <= 10 ? .red : .purple
                                    )
                                }
                            }
                            
                            Text(formatDate(item.date))
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                
                if item.isSensitive {
                    Button {
                        viewModel.toggleReveal(for: item)
                    } label: {
                        Image(systemName: item.isRevealed ? "eye.slash" : "eye")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .padding(.top, 2)
                    }
                    .buttonStyle(.plain)
                    .help(item.isRevealed ? LocalizationHelper.Strings.hide : LocalizationHelper.Strings.reveal)
                }
            }
            
            // Geliştirici aksiyonları
            if viewModel.showDevTools {
                DevActionsBar(item: item, viewModel: viewModel)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
        
        Divider()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.locale = LocalizationHelper.isTurkish ? Locale(identifier: "tr_TR") : Locale.current
        
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return formatter.string(from: date)
        }
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Dev actions

struct DevActionsBar: View {
    let item: ClipboardItem
    @ObservedObject var viewModel: ClipboardViewModel
    
    var body: some View {
        Group {
            switch item.contentKind {
            case .json:
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        DevActionButton(title: LocalizationHelper.Strings.copyAsSwift) {
                            viewModel.copySwiftStruct(from: item)
                        }
                        DevActionButton(title: LocalizationHelper.Strings.copyAsTypeScript) {
                            viewModel.copyTypeScript(from: item)
                        }
                        DevActionButton(title: LocalizationHelper.Strings.copyAsCSharp) {
                            viewModel.copyCSharp(from: item)
                        }
                        DevActionButton(title: LocalizationHelper.Strings.formatJSON) {
                            viewModel.formatJSON(from: item)
                        }
                        DevActionButton(title: LocalizationHelper.Strings.minifyJSON) {
                            viewModel.minifyJSON(from: item)
                        }
                    }
                }
            case .base64:
                DevActionButton(title: LocalizationHelper.Strings.decode) {
                    viewModel.decodeBase64(from: item)
                }
            case .urlEncoded:
                DevActionButton(title: LocalizationHelper.Strings.decode) {
                    viewModel.decodeURL(from: item)
                }
            default:
                EmptyView()
            }
        }
    }
}

struct DevActionButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.accentColor.opacity(0.15))
                .foregroundColor(.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
    }
}

struct BadgeView: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.system(size: 9, weight: .semibold))
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .clipShape(RoundedRectangle(cornerRadius: 3))
    }
}

#Preview {
    let viewModel = ClipboardViewModel()
    return MenuBarList(viewModel: viewModel)
}
