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

    var body: some Scene {

        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }

        Window(
            "Current Watchers",
            id: "watchers"
        ) {
            WatcherListView()
                .environmentObject(appState)
        }
        
        Window(
            "Favourite Artists",
            id: "favourites"
        ) {
            FavouritesView()
                .environmentObject(appState)
        }
        
        Window(
            "Report History",
            id: "report-history"
        ) {
            ReportHistoryView()
        }
        
        Window(
            "Latest Report",
            id: "report"
        ) {
            ReportView()
                .environmentObject(appState)
        }
        
        Settings {
            SettingsView()
        }
    }
}
