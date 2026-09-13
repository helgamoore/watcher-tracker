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
}   