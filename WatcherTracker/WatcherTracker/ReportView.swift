//
//  ReportView.swift
//  WatcherTracker
//
//  Created by Helga Moore on 14/09/2026.
//

import SwiftUI
import AppKit

struct ReportView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Group {
            if let report = appState.lastReport {
                reportContent(report)
            } else {
                ContentUnavailableView(
                    "No Report",
                    systemImage: "doc.text",
                    description: Text("Process a watcher file to create a report.")
                )
            }
        }
        .padding(24)
        .frame(
            minWidth: 500,
            minHeight: 400
        )
    }

    private func openProfile(_ username: String) {
        guard let encodedUsername = username.addingPercentEncoding(
            withAllowedCharacters: .urlPathAllowed
        ) else {
            return
        }

        guard let url = URL(
            string: "https://www.deviantart.com/\(encodedUsername)"
        ) else {
            return
        }

        NSWorkspace.shared.open(url)
    }
    
    private func reportContent(
        _ report: WatcherReport
    ) -> some View {

        VStack(alignment: .leading, spacing: 20) {

            Text("Watcher Report")
                .font(.title)

            HStack(spacing: 24) {

                Label(
                    "\(report.added.count) added",
                    systemImage: "plus.circle"
                )

                Label(
                    "\(report.removed.count) removed",
                    systemImage: "minus.circle"
                )

                Label(
                    "\(report.total) total",
                    systemImage: "person.2"
                )
            }

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    reportGroup(
                        title: "Added Watchers",
                        symbol: "+",
                        watchers: report.added
                    )

                    reportGroup(
                        title: "Removed Watchers",
                        symbol: "−",
                        watchers: report.removed
                    )
                }
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
            }
        }
    }

    @ViewBuilder
    private func reportGroup(
        title: String,
        symbol: String,
        watchers: [String]
    ) -> some View {

        VStack(alignment: .leading, spacing: 8) {

            Text("\(title) (\(watchers.count))")
                .font(.headline)

            if watchers.isEmpty {

                Text("None")
                    .foregroundStyle(.secondary)

            } else {

                ForEach(watchers, id: \.self) { watcher in
                    Button {
                        openProfile(watcher)
                    } label: {
                        HStack(spacing: 8) {
                            Text(symbol)

                            Text(watcher)
                                .font(.system(.body, design: .monospaced))
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.link)
                    .onHover { hovering in
                        if hovering {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    let state = AppState()

    state.lastReport = WatcherReport(
        date: Date(),
        added: [
            "Alice",
            "Diana"
        ],
        removed: [
            "Charlie"
        ],
        total: 1078
    )

    return ReportView()
        .environmentObject(state)
}
