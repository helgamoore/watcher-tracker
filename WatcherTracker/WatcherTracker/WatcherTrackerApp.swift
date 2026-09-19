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
            "Local AI",
            id: "local-image-generator"
        ) {
            LocalImageGeneratorView()
        }

        Window(
            "Apple Image Generator",
            id: "apple-image-playground"
        ) {
            AppleImageGeneratorView()
        }

        Window(
            "Gemini",
            id: "gemini-image-generator"
        ) {
            GeminiImageGeneratorView()
        }

        Window(
            "ChatGPT",
            id: "chatgpt-image-generator"
        ) {
            ChatGPTImageGeneratorView()
        }
             
        WindowGroup(
            "Image Preview",
            for: URL.self
        ) { $imageURL in

            if let imageURL {

                GeneratedImagePreviewView(
                    imageURL:
                        imageURL
                )

            } else {

                ContentUnavailableView(
                    "No Image",
                    systemImage:
                        "photo"
                )
            }
        }
        
        Settings {
            SettingsView()
        }
    }
}
