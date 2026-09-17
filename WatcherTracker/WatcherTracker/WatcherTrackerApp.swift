//
//  WatcherTrackerApp.swift
//  WatcherTracker
//
//  Created by Helga Moore on 13/09/2026.
//

import SwiftUI

@main
struct WatcherTrackerApp: App {

    @StateObject private var appState = AppState()

    @AppStorage("watchersWindowOpen")
    private var watchersWindowOpen = false

    @AppStorage("favouritesWindowOpen")
    private var favouritesWindowOpen = false

    @AppStorage("reportWindowOpen")
    private var reportWindowOpen = false

    @AppStorage("historyWindowOpen")
    private var historyWindowOpen = false
    
    var body: some Scene {

        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .background(
                    WindowFrameAutosaver(
                        name: "MainWindow"
                    )
                )
        }

        Window(
            "Current Watchers",
            id: "watchers"
        ) {
            WatcherListView()
                .environmentObject(appState)
                .background(
                    WindowFrameAutosaver(
                        name: "WatcherListWindow"
                    )
                )
                .background(
                    WindowOpenStateTracker(
                        storageKey: "watcherListWindowOpen"
                    )
                )
        }
        
        Window(
            "Favourite Artists",
            id: "favourites"
        ) {
            FavouritesView()
                .environmentObject(appState)
                .background(
                    WindowFrameAutosaver(
                        name: "FavouritesWindow"
                    )
                )
                .background(
                    WindowOpenStateTracker(
                        storageKey: "favouritesWindowOpen"
                    )
                )
        }
        
        Window(
            "Report History",
            id: "report-history"
        ) {
            ReportHistoryView()
                .background(
                    WindowFrameAutosaver(
                        name: "ReportHistoryWindow"
                    )
                )
                .background(
                    WindowOpenStateTracker(
                        storageKey: "reportHistoryWindowOpen"
                    )
                )
        }
        
        Window(
            "Latest Report",
            id: "report"
        ) {
            ReportView()
                .environmentObject(appState)
                .background(
                    WindowFrameAutosaver(
                        name: "LatestReportWindow"
                    )
                )
                .background(
                    WindowOpenStateTracker(
                        storageKey: "latestReportWindowOpen"
                    )
                )
        }
        
        Window(
            "Apple Image Playground",
            id: "apple-image-playground"
        ) {
            ImagePlaygroundGeneratorView()
        }
                
        Settings {
            SettingsView()
        }
    }
}
