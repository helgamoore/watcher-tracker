//
//  WatcherListView.swift
//  WatcherTracker
//
//  Created by Helga Moore on 15/09/2026.
//

import SwiftUI
import AppKit

struct WatcherListView: View {
    @EnvironmentObject private var appState: AppState
    @State private var searchText = ""

    var body: some View {
        Group {
            if let snapshot = appState.currentSnapshot {
                watcherList(snapshot)
            } else {
                ContentUnavailableView(
                    "No Watcher List",
                    systemImage: "person.2",
                    description: Text(
                        "No archived watcher list is available."
                    )
                )
            }
        }
        .frame(
            minWidth: 550,
            minHeight: 650
        )
    }

    private func watcherList(
        _ snapshot: WatcherSnapshot
    ) -> some View {

        let groups = groupedWatchers(filteredWatchers)
        let availableLetters = groups.keys.sorted()

        return VStack(spacing: 0) {

            VStack(alignment: .leading, spacing: 12) {

                HStack {
                    Text("Current Watchers")
                        .font(.title2)

                    Spacer()

                    Text("\(filteredWatchers.count) watchers")
                        .foregroundStyle(.secondary)
                }

                TextField(
                    "Filter watchers",
                    text: $searchText
                )
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 320)
            }
            .padding()

            Divider()

            if filteredWatchers.isEmpty {
                ContentUnavailableView(
                    "No Matching Watchers",
                    systemImage: "magnifyingglass",
                    description: Text(
                        "Try a different filter."
                    )
                )
            } else {
                ScrollViewReader { proxy in

                    HStack(spacing: 0) {

                        VStack(spacing: 3) {
                            ForEach(
                                availableLetters,
                                id: \.self
                            ) { letter in

                                Button(letter) {
                                    withAnimation {
                                        proxy.scrollTo(
                                            letter,
                                            anchor: .top
                                        )
                                    }
                                }
                                .buttonStyle(.plain)
                                .font(.caption.bold())
                                .foregroundStyle(.link)
                            }
                        }
                        .padding(.horizontal, 10)

                        Divider()

                        List {
                            ForEach(
                                availableLetters,
                                id: \.self
                            ) { letter in

                                Section {
                                    ForEach(
                                        groups[letter] ?? [],
                                        id: \.self
                                    ) { watcher in

                                        watcherLink(watcher)
                                    }

                                } header: {
                                    Text(letter)
                                        .font(.headline)
                                        .id(letter)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func watcherLink(
        _ watcher: String
    ) -> some View {

        Group {
            if let username =
                watcher.addingPercentEncoding(
                    withAllowedCharacters: .urlPathAllowed
                ),
               let url = URL(
                    string:
                        "https://www.deviantart.com/\(username)"
               ) {

                Link(destination: url) {
                    Text(watcher)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.link)
                .onHover { hovering in
                    if hovering {
                        NSCursor.pointingHand.set()
                    } else {
                        NSCursor.arrow.set()
                    }
                }

            } else {
                Text(watcher)
            }
        }
    }

    private func groupedWatchers(
        _ watchers: [String]
    ) -> [String: [String]] {

        Dictionary(grouping: watchers) { watcher in

            guard let first = watcher.first else {
                return "#"
            }

            let character =
                String(first).uppercased()

            if character.first?.isLetter == true {
                return character
            }

            return "#"
        }
    }

    private var filteredWatchers: [String] {
        guard let snapshot = appState.currentSnapshot else {
            return []
        }

        let query = searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !query.isEmpty else {
            return snapshot.watchers
        }

        return snapshot.watchers.filter {
            $0.localizedCaseInsensitiveContains(query)
        }
    }
}
