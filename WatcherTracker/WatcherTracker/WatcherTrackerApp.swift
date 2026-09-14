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
