//
//  MenuBarList.swift
//  ClipHistory
//
//  Created by Onur Akyüz on 25.12.2025.
//

import SwiftUI

/// Menü çubuğunda gösterilecek ana liste görünümü
struct MenuBarList: View {
    @ObservedObject var viewModel: ClipboardViewModel
    
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
                // Boş durum
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
                // Öğe listesi
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(viewModel.items) { item in
                            ClipboardItemRow(item: item, viewModel: viewModel)
                        }
                    }
                }
                .frame(maxHeight: 400)
            }
            
            Divider()
            
            // Alt butonlar
            VStack(spacing: 0) {
                Button(action: {
                    viewModel.clearHistory()
                }) {
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
                
                Button(action: {
                    viewModel.toggleLaunchAtLogin()
                }) {
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
                
                Button(action: {
                    viewModel.quit()
                }) {
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
        .frame(width: 300)
    }
}

/// Liste öğesi satırı
struct ClipboardItemRow: View {
    let item: ClipboardItem
    @ObservedObject var viewModel: ClipboardViewModel
    
    var body: some View {
        Button(action: {
            viewModel.copyToPasteboard(item)
        }) {
            VStack(alignment: .leading, spacing: 4) {
                // Metin (maksimum 2 satır)
                Text(item.text)
                    .font(.system(size: 13))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.primary)
                
                // Tarih
                Text(formatDate(item.date))
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .background(Color(NSColor.controlBackgroundColor))
        
        Divider()
    }
    
    /// Tarihi formatlar
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        // Sistem diline göre locale ayarla
        formatter.locale = LocalizationHelper.isTurkish ? Locale(identifier: "tr_TR") : Locale.current
        
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return formatter.string(from: date)
        } else {
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }
}

#Preview {
    let viewModel = ClipboardViewModel()
    return MenuBarList(viewModel: viewModel)
}

