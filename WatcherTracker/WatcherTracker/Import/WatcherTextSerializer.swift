import Foundation

struct WatcherTextSerializer {

    func serialize(_ snapshot: WatcherSnapshot) -> String {
        snapshot.watchers.joined(separator: "\n")
    }

    func serialize(_ report: WatcherReport) -> String {
        var lines: [String] = []

        lines.append("Report on watchers")
        lines.append("Added Watchers \(report.added.count):")

        for watcher in report.added {
            lines.append("+ \(watcher)")
        }

        lines.append("Removed Watchers \(report.removed.count):")

        for watcher in report.removed {
            lines.append("- \(watcher)")
        }

        lines.append("Total Current Watchers: \(report.total)")

        return lines.joined(separator: "\n")
    }

    func deserializeSnapshot(
        from text: String,
        date: Date
    ) -> WatcherSnapshot {

        let watchers = text
            .components(separatedBy: .newlines)
            .map {
                $0.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .filter {
                !$0.isEmpty
            }

        return WatcherSnapshot(
            date: date,
            watchers: watchers
        )
    }
    
    func deserializeReport(
        from text: String,
        date: Date
    ) -> WatcherReport {

        let lines = text
            .components(separatedBy: .newlines)
            .map {
                $0.trimmingCharacters(in: .whitespacesAndNewlines)
            }

        var added: [String] = []
        var removed: [String] = []
        var total = 0

        enum Section {
            case none
            case added
            case removed
        }

        var section: Section = .none

        for line in lines {
            if line.hasPrefix("Added Watchers") {
                section = .added
                continue
            }

            if line.hasPrefix("Removed Watchers") {
                section = .removed
                continue
            }

            if line.hasPrefix("Total Current Watchers:") {
                let value = line
                    .replacingOccurrences(
                        of: "Total Current Watchers:",
                        with: ""
                    )
                    .trimmingCharacters(in: .whitespaces)

                total = Int(value) ?? 0
                continue
            }

            switch section {
            case .added:
                if line.hasPrefix("+ ") {
                    added.append(
                        String(line.dropFirst(2))
                    )
                }

            case .removed:
                if line.hasPrefix("- ") {
                    removed.append(
                        String(line.dropFirst(2))
                    )
                }

            case .none:
                break
            }
        }

        return WatcherReport(
            date: date,
            added: added,
            removed: removed,
            total: total
        )
    }
}
