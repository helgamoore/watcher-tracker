import Foundation

struct WatcherTrackerService {

    private let importer = TextWatcherImporter()
    private let comparator = WatcherComparator()
    private let archive = WatcherArchive()

    func process(
        sourceURL: URL,
        archiveFolderURL: URL,
        date: Date = Date()
    ) throws -> WatcherReport {

        let sourceAccess = sourceURL.startAccessingSecurityScopedResource()
        let archiveAccess = archiveFolderURL.startAccessingSecurityScopedResource()

        defer {
            if sourceAccess {
                sourceURL.stopAccessingSecurityScopedResource()
            }

            if archiveAccess {
                archiveFolderURL.stopAccessingSecurityScopedResource()
            }
        }

        // Important: find the previous snapshot BEFORE saving today's one.
        let previousSnapshotURL = try archive.latestSnapshotURL(
            in: archiveFolderURL
        )

        let rawText = try String(
            contentsOf: sourceURL,
            encoding: .utf8
        )

        let currentSnapshot = importer.importWatchers(
            from: rawText,
            date: date
        )

        let previousSnapshot: WatcherSnapshot

        if let previousSnapshotURL {
            previousSnapshot = try archive.loadSnapshot(
                from: previousSnapshotURL
            )
        } else {
            previousSnapshot = WatcherSnapshot(
                date: date,
                watchers: []
            )
        }

        let report = comparator.compare(
            current: currentSnapshot,
            previous: previousSnapshot
        )

        try archive.save(
            currentSnapshot,
            to: archiveFolderURL
        )

        try archive.save(
            report,
            to: archiveFolderURL
        )

        try FileManager.default.removeItem(
            at: sourceURL
        )

        return report
    }
}