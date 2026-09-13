import Foundation

struct WatcherSnapshot {
    let date: Date
    let watchers: [String]
    
    var count: Int {
        return watchers.count
    }
}