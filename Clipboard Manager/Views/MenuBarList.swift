import SwiftUI
import AppKit


struct MenuBarList: View {
    @ObservedObject var viewModel: ClipboardViewModel
    @State private var showSmartRules = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            HStack {
                Text(LocalizationHelper.Strings.title)
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 6)
            .background(Color(NSColor.controlBackgroundColor))


            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 12))
                TextField(LocalizationHelper.Strings.searchPlaceholder, text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color(NSColor.textBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 12)
            .padding(.bottom, 8)


            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(HistoryFilter.allCases) { filter in
                        FilterPill(
                            title: LocalizationHelper.Strings.filterTitle(filter),
                            isSelected: viewModel.selectedFilter == filter
                        ) {
                            viewModel.selectedFilter = filter
                        }
                    }
                }
                .padding(.horizontal, 12)
            }
            .padding(.bottom, 8)

            Divider()


            let visible = viewModel.filteredItems
            if visible.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: viewModel.items.isEmpty ? "doc.on.clipboard" : "line.3.horizontal.decrease.circle")
                        .font(.system(size: 28))
                        .foregroundColor(.secondary)
                    Text(viewModel.items.isEmpty
                         ? LocalizationHelper.Strings.emptyState
                         : LocalizationHelper.Strings.emptyFilter)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 36)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(visible) { item in
                            ClipboardItemRow(item: item, viewModel: viewModel)
                        }
                    }
                }
                .frame(maxHeight: 420)
            }

            Divider()

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
                .disabled(viewModel.items.filter { !$0.isPinned }.isEmpty)

                Divider()

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
        .frame(width: 380)
    }
}


struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isSelected ? Color.accentColor.opacity(0.2) : Color(NSColor.controlBackgroundColor))
                .foregroundColor(isSelected ? .accentColor : .primary)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.accentColor.opacity(0.5) : Color.secondary.opacity(0.25), lineWidth: 1)
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}


struct SmartRulesPanel: View {
    @ObservedObject var viewModel: ClipboardViewModel

    private let timeoutOptions = [30, 60, 120, 300]
    private let maxOptions = [15, 30, 50]

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

            HStack {
                Text(LocalizationHelper.Strings.maxHistory)
                    .font(.system(size: 12))
                Spacer()
                Picker("", selection: $viewModel.maxItems) {
                    ForEach(maxOptions, id: \.self) { value in
                        Text("\(value)").tag(value)
                    }
                }
                .labelsHidden()
                .frame(width: 70)
            }
        }
        .padding(.top, 4)
    }
}


struct ClipboardItemRow: View {
    let item: ClipboardItem
    @ObservedObject var viewModel: ClipboardViewModel
    @State private var isHovered = false

    private var justCopied: Bool {
        viewModel.lastCopiedItemId == item.id
    }

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
                            if item.isPinned {
                                Image(systemName: "pin.fill")
                                    .font(.system(size: 9))
                                    .foregroundColor(.orange)
                                    .padding(.top, 3)
                            }

                            contentLeadingIcon

                            Text(item.displayText)
                                .font(.system(size: 13, design: item.isSensitive && !item.isRevealed ? .monospaced : .default))
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                                .foregroundColor(.primary)

                            Spacer(minLength: 0)
                        }


                        secondaryPreview

                        HStack(spacing: 6) {
                            if justCopied {
                                BadgeView(text: LocalizationHelper.Strings.copiedBadge, color: .green)
                                    .transition(.opacity.combined(with: .scale))
                            }

                            if item.wasURLCleaned {
                                BadgeView(text: LocalizationHelper.Strings.cleanedBadge, color: .green)
                            }

                            contentBadge

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
                        .animation(.easeInOut(duration: 0.2), value: justCopied)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)


                if isHovered || item.isSensitive {
                    HStack(spacing: 4) {
                        if item.isSensitive {
                            IconActionButton(
                                systemName: item.isRevealed ? "eye.slash" : "eye",
                                help: item.isRevealed ? LocalizationHelper.Strings.hide : LocalizationHelper.Strings.reveal
                            ) {
                                viewModel.toggleReveal(for: item)
                            }
                        }

                        if isHovered {
                            IconActionButton(
                                systemName: item.isPinned ? "pin.slash" : "pin.fill",
                                help: item.isPinned ? LocalizationHelper.Strings.unpin : LocalizationHelper.Strings.pin
                            ) {
                                viewModel.togglePin(for: item)
                            }

                            IconActionButton(systemName: "doc.on.doc", help: LocalizationHelper.Strings.copy) {
                                viewModel.copyToPasteboard(item)
                            }

                            IconActionButton(systemName: "trash", help: LocalizationHelper.Strings.delete) {
                                viewModel.removeItem(item)
                            }
                        }
                    }
                    .padding(.top, 1)
                }
            }

            if viewModel.showDevTools {
                DevActionsBar(item: item, viewModel: viewModel)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isHovered ? Color.accentColor.opacity(0.06) : Color(NSColor.controlBackgroundColor))
        .onHover { hovering in
            isHovered = hovering
        }

        Divider()
    }

    @ViewBuilder
    private var contentLeadingIcon: some View {
        if case .hexColor(let hex) = item.contentKind,
           let nsColor = DevConverter.nsColor(fromHex: hex) {
            Circle()
                .fill(Color(nsColor))
                .frame(width: 12, height: 12)
                .overlay(Circle().stroke(Color.secondary.opacity(0.4), lineWidth: 0.5))
                .padding(.top, 2)
        }
    }

    @ViewBuilder
    private var secondaryPreview: some View {
        switch item.contentKind {
        case .unixTimestamp(let dateString):
            Text(dateString)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .lineLimit(1)
        case .jwtToken(_, let payload):
            Text(payload.replacingOccurrences(of: "\n", with: " "))
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.secondary)
                .lineLimit(1)
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private var contentBadge: some View {
        switch item.contentKind {
        case .json:
            BadgeView(text: LocalizationHelper.Strings.jsonBadge, color: .orange)
        case .jwtToken:
            BadgeView(text: LocalizationHelper.Strings.jwtBadge, color: .purple)
        case .curlCommand:
            BadgeView(text: LocalizationHelper.Strings.curlBadge, color: .blue)
        case .unixTimestamp:
            BadgeView(text: "Epoch", color: Color(red: 0.0, green: 0.6, blue: 0.6))
        default:
            EmptyView()
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.locale = LocalizationHelper.isTurkish ? Locale(identifier: "tr_TR") : Locale.current

        if Calendar.current.isDateInToday(date) {
            return formatter.string(from: date)
        }
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

struct IconActionButton: View {
    let systemName: String
    let help: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .frame(width: 20, height: 20)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(help)
    }
}


struct DevActionsBar: View {
    let item: ClipboardItem
    @ObservedObject var viewModel: ClipboardViewModel

    var body: some View {
        Group {
            switch item.contentKind {
            case .json:
                actionScroll {
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
            case .jwtToken:
                DevActionButton(title: LocalizationHelper.Strings.copyJWTPayload) {
                    viewModel.copyJWTPayload(from: item)
                }
            case .curlCommand:
                actionScroll {
                    DevActionButton(title: LocalizationHelper.Strings.copySwiftURLRequest) {
                        viewModel.copyCurlAsSwift(from: item)
                    }
                    DevActionButton(title: LocalizationHelper.Strings.copyJSFetch) {
                        viewModel.copyCurlAsJSFetch(from: item)
                    }
                }
            case .unixTimestamp:
                DevActionButton(title: LocalizationHelper.Strings.copyISO8601) {
                    viewModel.copyTimestampISO(from: item)
                }
            case .base64:
                DevActionButton(title: LocalizationHelper.Strings.decode) {
                    viewModel.decodeBase64(from: item)
                }
            case .urlEncoded:
                DevActionButton(title: LocalizationHelper.Strings.decode) {
                    viewModel.decodeURL(from: item)
                }
            case .plain, .url, .hexColor:

                if item.text.count <= 120, item.text.contains(where: { $0.isLetter }) {
                    actionScroll {
                        DevActionButton(title: LocalizationHelper.Strings.camelCase) {
                            viewModel.copyCamelCase(from: item)
                        }
                        DevActionButton(title: LocalizationHelper.Strings.snakeCase) {
                            viewModel.copySnakeCase(from: item)
                        }
                        DevActionButton(title: LocalizationHelper.Strings.kebabCase) {
                            viewModel.copyKebabCase(from: item)
                        }
                        DevActionButton(title: LocalizationHelper.Strings.upperCase) {
                            viewModel.copyUpperSnakeCase(from: item)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func actionScroll<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                content()
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
