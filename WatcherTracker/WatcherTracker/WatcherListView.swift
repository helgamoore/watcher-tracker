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
    @State private var favourites: Set<String> = []
    @State private var favouritesOnly = false

    private let favouritesStore = WatcherFavouritesStore()
    private let bookmarkStore = BookmarkStore()
    
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

                HStack {
                    TextField(
                        "Filter watchers",
                        text: $searchText
                    )
                    .textFieldStyle(.roundedBorder)

                    Button {
                        favouritesOnly.toggle()
                    } label: {
                        Image(
                            systemName:
                                favouritesOnly
                                ? "star.fill"
                                : "star"
                        )
                    }
                    .buttonStyle(.borderless)
                    .help(
                        favouritesOnly
                        ? "Show all watchers"
                        : "Show favourites only"
                    )
                }
                .frame(maxWidth: 360)
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
        .onAppear {
            loadFavourites()
        }
    }

    private func watcherLink(
        _ watcher: String
    ) -> some View {

        HStack(spacing: 8) {

            Button {
                toggleFavourite(watcher)
            } label: {
                Image(
                    systemName:
                        favourites.contains(watcher)
                        ? "star.fill"
                        : "star"
                )
            }
            .buttonStyle(.borderless)
            .help(
                favourites.contains(watcher)
                ? "Remove from favourites"
                : "Add to favourites"
            )

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

            Spacer()
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

        var watchers = snapshot.watchers

        if favouritesOnly {
            watchers = watchers.filter {
                favourites.contains($0)
            }
        }

        let query = searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !query.isEmpty else {
            return watchers
        }

        return watchers.filter {
            $0.localizedCaseInsensitiveContains(query)
        }
    }
    
    private func loadFavourites() {
        guard let archiveFolderURL =
            bookmarkStore.loadArchiveFolder()
        else {
            return
        }

        let accessGranted =
            archiveFolderURL.startAccessingSecurityScopedResource()

        defer {
            if accessGranted {
                archiveFolderURL.stopAccessingSecurityScopedResource()
            }
        }

        do {
            favourites = try favouritesStore.load(
                from: archiveFolderURL
            )
        } catch {
            print("Unable to load favourites:", error)
        }
    }
    
    private func saveFavourites() {
        guard let archiveFolderURL =
            bookmarkStore.loadArchiveFolder()
        else {
            return
        }

        let accessGranted =
            archiveFolderURL.startAccessingSecurityScopedResource()

        defer {
            if accessGranted {
                archiveFolderURL.stopAccessingSecurityScopedResource()
            }
        }

        do {
            try favouritesStore.save(
                favourites,
                to: archiveFolderURL
            )
        } catch {
            print("Unable to save favourites:", error)
        }
    }
    
    private func toggleFavourite(_ watcher: String) {
        if favourites.contains(watcher) {
            favourites.remove(watcher)
        } else {
            favourites.insert(watcher)
        }

        saveFavourites()
    }
}
