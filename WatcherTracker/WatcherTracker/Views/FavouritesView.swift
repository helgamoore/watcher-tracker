//
//  FavouritesView.swift
//  WatcherTracker
//
//  Created by Helga Moore on 15/09/2026.
//

import SwiftUI
import AppKit

struct FavouritesView: View {
    @EnvironmentObject private var appState: AppState

    @State private var searchText = ""
    @State private var newFavourite = ""
    @State private var errorMessage: String?

    private let favouritesStore = FavouriteArtistsStore()
    private let bookmarkStore = BookmarkStore()

    var body: some View {
        VStack(spacing: 0) {

            header

            Divider()

            addSection

            Divider()

            if filteredFavourites.isEmpty {
                ContentUnavailableView(
                    searchText.isEmpty
                        ? "No Favourites"
                        : "No Matching Favourites",
                    systemImage: "star",
                    description: Text(
                        searchText.isEmpty
                            ? "Add an artist to your favourites."
                            : "Try a different filter."
                    )
                )
            } else {
                favouriteList
            }

            if let errorMessage {
                Divider()

                Text(errorMessage)
                    .foregroundStyle(.red)
                    .padding()
            }
        }
        .frame(
            minWidth: 500,
            minHeight: 600
        )
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack {
                Label(
                    "Favourite Artists",
                    systemImage: "star.fill"
                )
                .font(.title2)

                Spacer()

                Text("\(appState.favourites.count) favourites")
                    .foregroundStyle(.secondary)
            }

            TextField(
                "Filter favourites",
                text: $searchText
            )
            .textFieldStyle(.roundedBorder)
            .frame(maxWidth: 320)
        }
        .padding()
    }

    // MARK: - Add

    private var addSection: some View {
        HStack {
            TextField(
                "DeviantArt username",
                text: $newFavourite
            )
            .textFieldStyle(.roundedBorder)

            Button {
                addFavourite()
            } label: {
                Label(
                    "Add",
                    systemImage: "plus"
                )
            }
            .disabled(cleanNewFavourite.isEmpty)
        }
        .padding()
    }

    // MARK: - List

    private var favouriteList: some View {
        List {
            ForEach(
                filteredFavourites,
                id: \.self
            ) { watcher in

                HStack(spacing: 10) {

                    Image(systemName: "star.fill")
                        .foregroundStyle(.secondary)

                    profileLink(watcher)

                    Spacer()

                    Button {
                        removeFavourite(watcher)
                    } label: {
                        Image(systemName: "minus.circle")
                    }
                    .buttonStyle(.borderless)
                    .help("Remove from favourites")
                }
            }
        }
    }

    // MARK: - Profile Link

    @ViewBuilder
    private func profileLink(
        _ username: String
    ) -> some View {

        if let encoded =
            username.addingPercentEncoding(
                withAllowedCharacters: .urlPathAllowed
            ),
           let url = URL(
                string: "https://www.deviantart.com/\(encoded)"
           ) {

            Link(destination: url) {
                Text(username)
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
            Text(username)
        }
    }

    // MARK: - Filtering

    private var filteredFavourites: [String] {
        let query = searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        return appState.favourites
            .filter {
                query.isEmpty ||
                $0.localizedCaseInsensitiveContains(query)
            }
            .sorted {
                $0.localizedCaseInsensitiveCompare($1)
                    == .orderedAscending
            }
    }

    // MARK: - Add / Remove

    private var cleanNewFavourite: String {
        newFavourite.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }

    private func addFavourite() {
        let username = cleanNewFavourite

        guard !username.isEmpty else {
            return
        }

        appState.favourites.insert(username)

        saveFavourites()

        newFavourite = ""
    }

    private func removeFavourite(
        _ username: String
    ) {
        appState.favourites.remove(username)

        saveFavourites()
    }

    // MARK: - Persistence

    private func saveFavourites() {
        guard let archiveFolderURL =
            bookmarkStore.loadArchiveFolder()
        else {
            errorMessage =
                "Archive folder is not available."
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
                appState.favourites,
                to: archiveFolderURL
            )

            errorMessage = nil

        } catch {
            errorMessage =
                "Saving favourites error: \(error.localizedDescription)"
        }
    }
}

#Preview {
    let state = AppState()

    state.favourites = [
        "Mimic876",
        "Magic-Marcus",
        "StageMagicFixation"
    ]

    return FavouritesView()
        .environmentObject(state)
}
