//
//  ContentView.swift
//  WatcherTracker
//
//  Created by Helga Moore on 13/09/2026.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hi, I'm WatcherTracker.")
            Text("WatcherTracker is a SwiftUI macOS utility for cleaning, archiving, and comparing DeviantArt watcher lists. It tracks new and removed watchers, stores dated snapshots, and is planned to support the DeviantArt API, iCloud, iOS, and iPadOS.")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
