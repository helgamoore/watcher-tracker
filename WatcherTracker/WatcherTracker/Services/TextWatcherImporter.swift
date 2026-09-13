import Foundation

struct TextWatcherImporter {

    func importWatchers(
        from text: String,
        date: Date = Date()
    ) -> WatcherSnapshot {

        let watchers = text
            .components(separatedBy: .newlines)
            .map {
                $0.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .filter {
                !$0.isEmpty
            }
            .filter {
                !$0.lowercased().hasSuffix("'s avatar")
            }

        let sortedWatchers = Set(watchers)
            .sorted {
                $0.localizedCaseInsensitiveCompare($1) == .orderedAscending
            }

        return WatcherSnapshot(
            date: date,
            watchers: sortedWatchers
        )
    }
}