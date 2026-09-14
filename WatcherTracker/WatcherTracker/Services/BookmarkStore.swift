//
//  BookmarkStore.swift
//  WatcherTracker
//
//  Created by Helga Moore on 13/09/2026.
//

import Foundation

struct BookmarkStore {

    private enum Keys {
        static let sourceFolder = "sourceFolderBookmark"
        static let archiveFolder = "archiveFolderBookmark"
        static let lastProcessedFileName = "lastProcessedFileName"
    }

    // MARK: - Source folder

    func saveSourceFolder(_ url: URL) throws {
        try saveBookmark(
            for: url,
            key: Keys.sourceFolder
        )
    }

    func loadSourceFolder() -> URL? {
        loadBookmark(
            key: Keys.sourceFolder
        )
    }

    // MARK: - Archive folder

    func saveArchiveFolder(_ url: URL) throws {
        try saveBookmark(
            for: url,
            key: Keys.archiveFolder
        )
    }

    func loadArchiveFolder() -> URL? {
        loadBookmark(
            key: Keys.archiveFolder
        )
    }

    // MARK: - Last processed file

    func saveLastProcessedFileName(_ name: String) {
        UserDefaults.standard.set(
            name,
            forKey: Keys.lastProcessedFileName
        )
    }

    func loadLastProcessedFileName() -> String? {
        UserDefaults.standard.string(
            forKey: Keys.lastProcessedFileName
        )
    }

    // MARK: - Security-scoped bookmarks

    private func saveBookmark(
        for url: URL,
        key: String
    ) throws {

        let data = try url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )

        UserDefaults.standard.set(
            data,
            forKey: key
        )
    }

    private func loadBookmark(
        key: String
    ) -> URL? {

        guard let data = UserDefaults.standard.data(
            forKey: key
        ) else {
            return nil
        }

        var isStale = false

        do {
            let url = try URL(
                resolvingBookmarkData: data,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )

            if isStale {
                try saveBookmark(
                    for: url,
                    key: key
                )
            }

            return url

        } catch {
            print(
                "Unable to restore bookmark for \(key):",
                error
            )

            return nil
        }
    }
}
