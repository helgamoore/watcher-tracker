import Foundation

struct WatcherComparator {

    func compare(
        current: WatcherSnapshot,
        previous: WatcherSnapshot   
    ) -> WatcherReport {

        let currentWatchers = Set(current.watchers)
        let previousWatchers = Set(previous.watchers)

        let added = currentWatchers
            .subtracting(previousWatchers)
            .sorted {
                $0.localizedCaseInsensitiveCompare($1) == .orderedAscending
            }

        let removed = previousWatchers
            .subtracting(currentWatchers)
            .sorted {
                $0.localizedCaseInsensitiveCompare($1) == .orderedAscending
            }

        return WatcherReport(
            date: current.date,
            added: added,
            removed: removed,
            total: current.count
        )
    }
}