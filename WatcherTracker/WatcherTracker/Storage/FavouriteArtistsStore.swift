//
//  WatcherFavouritesStore.swift
//  WatcherTracker
//
//  Created by Helga Moore on 15/09/2026.
//

import Foundation

struct FavouriteArtistsStore {

    private let fileManager = FileManager.default

    private let fileName = "favourites.txt"

    func load(from archiveFolder: URL) throws -> Set<String> {
        let url = archiveFolder
            .appendingPathComponent(fileName)

        guard fileManager.fileExists(atPath: url.path) else {
            return []
        }

        let text = try String(
            contentsOf: url,
            encoding: .utf8
        )

        let watchers = text
            .components(separatedBy: .newlines)
            .map {
                $0.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
            }
            .filter {
                !$0.isEmpty
            }

        return Set(watchers)
    }

    func save(
        _ favourites: Set<String>,
        to archiveFolder: URL
    ) throws {

        let url = archiveFolder
            .appendingPathComponent(fileName)

        let text = favourites
            .sorted {
                $0.localizedCaseInsensitiveCompare($1)
                    == .orderedAscending
            }
            .joined(separator: "\n")

        try text.write(
            to: url,
            atomically: true,
            encoding: .utf8
        )
    }
}
