import Foundation

struct WatcherArchive {

    private let fileManager = FileManager.default
    private let serializer = WatcherTextSerializer()

    func latestSnapshotURL(in folder: URL) throws -> URL? {
        let files = try fileManager.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )

        let snapshotFiles = files.filter { url in
            let name = url.lastPathComponent

            return name.hasPrefix("watchers_")
                && name.hasSuffix(".txt")
                && !name.hasPrefix("watchers_report_")
        }

        return snapshotFiles
            .sorted { $0.lastPathComponent > $1.lastPathComponent }
            .first
    }

    func loadSnapshot(from url: URL) throws -> WatcherSnapshot {
        let text = try String(
            contentsOf: url,
            encoding: .utf8
        )

        let date = try date(fromSnapshotURL: url)

        return serializer.deserializeSnapshot(
            from: text,
            date: date
        )
    }

    func save(
        _ snapshot: WatcherSnapshot,
        to folder: URL
    ) throws -> URL {

        try ensureFolderExists(folder)

        let fileURL = folder.appendingPathComponent(
            snapshotFileName(for: snapshot.date)
        )

        let text = serializer.serialize(snapshot)

        try text.write(
            to: fileURL,
            atomically: true,
            encoding: .utf8
        )

        return fileURL
    }

    func save(
        _ report: WatcherReport,
        to folder: URL
    ) throws -> URL {

        try ensureFolderExists(folder)

        let fileURL = folder.appendingPathComponent(
            reportFileName(for: report.date)
        )

        let text = serializer.serialize(report)

        try text.write(
            to: fileURL,
            atomically: true,
            encoding: .utf8
        )

        return fileURL
    }

    private func ensureFolderExists(_ folder: URL) throws {
        var isDirectory: ObjCBool = false

        if fileManager.fileExists(
            atPath: folder.path,
            isDirectory: &isDirectory
        ) {
            if !isDirectory.boolValue {
                throw ArchiveError.notDirectory
            }

            return
        }

        try fileManager.createDirectory(
            at: folder,
            withIntermediateDirectories: true
        )
    }

    private func snapshotFileName(for date: Date) -> String {
        "watchers_\(dateString(from: date)).txt"
    }

    private func reportFileName(for date: Date) -> String {
        "watchers_report_\(dateString(from: date)).txt"
    }

    private func dateString(from date: Date) -> String {
        Self.dateFormatter.string(from: date)
    }

    private func date(fromSnapshotURL url: URL) throws -> Date {
        let name = url
            .deletingPathExtension()
            .lastPathComponent

        guard name.hasPrefix("watchers_") else {
            throw ArchiveError.invalidSnapshotFileName
        }

        let datePart = String(name.dropFirst("watchers_".count))

        guard let date = Self.dateFormatter.date(from: datePart) else {
            throw ArchiveError.invalidSnapshotFileName
        }

        return date
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    func latestReportURL(in folder: URL) throws -> URL? {
        let files = try fileManager.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )

        return files
            .filter { url in
                let name = url.lastPathComponent

                return name.hasPrefix("watchers_report_")
                    && name.hasSuffix(".txt")
            }
            .sorted {
                $0.lastPathComponent > $1.lastPathComponent
            }
            .first
    }
    
    func loadReport(from url: URL) throws -> WatcherReport {
        let text = try String(
            contentsOf: url,
            encoding: .utf8
        )

        let date = try date(fromReportURL: url)

        return serializer.deserializeReport(
            from: text,
            date: date
        )
    }
    
    private func date(fromReportURL url: URL) throws -> Date {
        let name = url
            .deletingPathExtension()
            .lastPathComponent

        guard name.hasPrefix("watchers_report_") else {
            throw ArchiveError.invalidReportFileName
        }

        let datePart = String(
            name.dropFirst("watchers_report_".count)
        )

        guard let date = Self.dateFormatter.date(
            from: datePart
        ) else {
            throw ArchiveError.invalidReportFileName
        }

        return date
    }
    
    func latestSnapshotURL(
        in folder: URL,
        before targetDate: Date
    ) throws -> URL? {

        let files = try fileManager.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )

        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: targetDate)

        let snapshots = try files.compactMap { url -> (URL, Date)? in
            let name = url.lastPathComponent

            guard
                name.hasPrefix("watchers_"),
                name.hasSuffix(".txt"),
                !name.hasPrefix("watchers_report_")
            else {
                return nil
            }

            let snapshotDate = try date(fromSnapshotURL: url)
            let snapshotDay = calendar.startOfDay(for: snapshotDate)

            guard snapshotDay < targetDay else {
                return nil
            }

            return (url, snapshotDate)
        }

        return snapshots
            .max { $0.1 < $1.1 }?
            .0
    }
    
    func reportURLs(in folder: URL) throws -> [URL] {
        let files = try fileManager.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )

        return try files
            .compactMap { url -> (URL, Date)? in
                let name = url.lastPathComponent

                guard
                    name.hasPrefix("watchers_report_"),
                    name.hasSuffix(".txt")
                else {
                    return nil
                }

                let reportDate = try date(fromReportURL: url)

                return (url, reportDate)
            }
            .sorted { $0.1 < $1.1 }
            .map(\.0)
    }
    
    func reports(in folder: URL) throws -> [Date: WatcherReport] {
        let urls = try reportURLs(in: folder)

        var result: [Date: WatcherReport] = [:]

        let calendar = Calendar.current

        for url in urls {
            let report = try loadReport(from: url)
            let day = calendar.startOfDay(for: report.date)

            result[day] = report
        }

        return result
    }
}

enum ArchiveError: Error {
    case notDirectory
    case invalidSnapshotFileName
    case invalidReportFileName
}
