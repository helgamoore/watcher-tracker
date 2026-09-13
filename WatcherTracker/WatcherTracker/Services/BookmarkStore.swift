//
//  BookmarkStore.swift
//  WatcherTracker
//
//  Created by Helga Moore on 13/09/2026.
//

import Foundation

struct BookmarkStore {

    private enum Keys {
        static let archiveFolder = "archiveFolderBookmark"
        static let sourceFile = "sourceFileBookmark"

        static let sourceFolderPath = "sourceFolderPath"
        static let sourceFileName = "sourceFileName"
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

    // MARK: - Source file

    func saveSourceFile(_ url: URL) throws {
        try saveBookmark(
            for: url,
            key: Keys.sourceFile
        )
    }

    func loadSourceFile() -> URL? {
        loadBookmark(
            key: Keys.sourceFile
        )
    }

    func clearSourceFile() {
        UserDefaults.standard.removeObject(
            forKey: Keys.sourceFile
        )
    }

    // MARK: - Source folder

    func saveSourceFolder(_ url: URL) {
        UserDefaults.standard.set(
            url.path,
            forKey: Keys.sourceFolderPath
        )
    }

    func loadSourceFolder() -> URL? {
        guard let path = UserDefaults.standard.string(
            forKey: Keys.sourceFolderPath
        ) else {
            return nil
        }

        return URL(fileURLWithPath: path)
    }

    // MARK: - Source file name

    func saveSourceFileName(_ name: String) {
        UserDefaults.standard.set(
            name,
            forKey: Keys.sourceFileName
        )
    }

    func loadSourceFileName() -> String? {
        UserDefaults.standard.string(
            forKey: Keys.sourceFileName
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
