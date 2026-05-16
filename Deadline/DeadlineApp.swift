//
//  DeadlineApp.swift
//  Deadline
//
//  Created by Neil on 19/11/2025.
//

import SwiftUI
import AppKit

@main
struct DeadlineApp: App {
    @StateObject private var menuBarModel = MenuBarDeadlineViewModel()

    var body: some Scene {
        WindowGroup(id: "main") {
            AppEntryView()
        }

        MenuBarExtra {
            MenuBarDeadlineMenu(viewModel: menuBarModel)
        } label: {
            MenuBarDeadlineLabel(viewModel: menuBarModel)
        }
        .menuBarExtraStyle(.window)
    }
}

private final class MenuBarDeadlineViewModel: ObservableObject {
    @Published var now = Date()
    @Published var countNext7Days = 0
    @Published var next3: [DeadlineItem] = []
    @Published var errorMessage: String?
    @Published var hasVault = false

    private let bookmarkKey = "LastOpenedVaultBookmark"

    func tick() {
        now = Date()
    }

    func refresh() {
        errorMessage = nil
        countNext7Days = 0
        next3 = []

        guard let url = resolveLastVaultURL() else {
            hasVault = false
            return
        }
        hasVault = true

        do {
            let items = try JSONManager(fileURL: url).load()
            let active = items.filter { !$0.isCompleted }

            let start = now
            let end = now.addingTimeInterval(7 * 24 * 60 * 60)
            let upcomingWithin7Days = active
                .filter { $0.targetDate >= start && $0.targetDate <= end }
                .sorted(by: { $0.targetDate < $1.targetDate })

            countNext7Days = upcomingWithin7Days.count
            next3 = Array(upcomingWithin7Days.prefix(3))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func timeRemainingString(target: Date) -> String {
        let diff = target.timeIntervalSince(now)
        if diff <= 0 { return "Expired" }

        let days = Int(diff) / 86400
        let hours = (Int(diff) % 86400) / 3600
        let minutes = (Int(diff) % 3600) / 60

        if days > 0 { return "\(days)d \(hours)h" }
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }

    func urgencyColor(for item: DeadlineItem) -> Color {
        let diff = item.targetDate.timeIntervalSince(now)
        if diff <= 0 { return .red }

        let days = diff / 86400
        if days > 14 {
            return .blue
        } else if days > 7 {
            return .green
        } else if days > 3 {
            return .orange
        } else {
            return .red
        }
    }

    private func resolveLastVaultURL() -> URL? {
        guard let data = UserDefaults.standard.data(forKey: bookmarkKey) else { return nil }

        var isStale = false
        do {
            let url = try URL(resolvingBookmarkData: data, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
            if isStale {
                let newData = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
                UserDefaults.standard.set(newData, forKey: bookmarkKey)
            }
            return url
        } catch {
            UserDefaults.standard.removeObject(forKey: bookmarkKey)
            errorMessage = error.localizedDescription
            return nil
        }
    }
}

private struct MenuBarDeadlineLabel: View {
    @ObservedObject var viewModel: MenuBarDeadlineViewModel

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock")
            Text("\(viewModel.countNext7Days)")
                .monospacedDigit()
        }
        .help("Deadlines due in the next 7 days")
        .onAppear { viewModel.refresh() }
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
            viewModel.refresh()
        }
    }
}

private struct MenuBarDeadlineMenu: View {
    @ObservedObject var viewModel: MenuBarDeadlineViewModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Deadline Monitor")
                        .font(.headline)
                    Text("\(viewModel.countNext7Days) due in next 7 days")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }


            }

            if let message = viewModel.errorMessage {
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else if viewModel.hasVault {
                if viewModel.next3.isEmpty {
                    Text("No deadlines within the next 7 days")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    VStack(spacing: 10) {
                        ForEach(viewModel.next3) { item in
                            MenuBarDeadlineRow(item: item, viewModel: viewModel)
                        }
                    }
                }
            } else {
                Text("Open the app to select a vault")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .frame(width: 340)
        .onAppear { viewModel.refresh() }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            viewModel.tick()
        }
    }
}

private struct MenuBarDeadlineRow: View {
    let item: DeadlineItem
    @ObservedObject var viewModel: MenuBarDeadlineViewModel

    var body: some View {
        let color = viewModel.urgencyColor(for: item)

        HStack(spacing: 10) {
            Capsule()
                .fill(color)
                .frame(width: 4)
                .padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .lineLimit(1)
                Text(item.targetDate, style: .date) + Text(" ") + Text(item.targetDate, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer(minLength: 12)

            Text(viewModel.timeRemainingString(target: item.targetDate))
                .font(.system(.body, design: .monospaced))
                .fontWeight(.semibold)
                .foregroundColor(color)
                .monospacedDigit()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
    }
}
