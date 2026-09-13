//
//  ContentView.swift
//  WatcherTracker
//
//  Created by Helga Moore on 13/09/2026.
//

import SwiftUI

struct ContentView: View {
    private let reportText: String = {
        let oldText = """
        Alice
        Bob
        Charlie
        """

        let newRawText = """
        Alice
        Bob's avatar
        Bob
        Diana's avatar
        Diana
        """

        let serializer = WatcherTextSerializer()

        let previous = serializer.deserializeSnapshot(
            from: oldText,
            date: Date()
        )

        let current = TextWatcherImporter().importWatchers(
            from: newRawText
        )

        let report = WatcherComparator().compare(
            current: current,
            previous: previous
        )

        let archive = WatcherArchive()

        let applicationSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!

        let folder = applicationSupport
            .appendingPathComponent("WatcherTracker")
            .appendingPathComponent("Archive")

        let snapshot = WatcherSnapshot(
            date: Date(),
            watchers: ["Alice", "Bob", "Diana"]
        )

        do {
            let url = try archive.save(snapshot, to: folder)
            print("Saved:", url.path)

            if let latest = try archive.latestSnapshotURL(in: folder) {
                print("Latest:", latest.path)

                let loaded = try archive.loadSnapshot(from: latest)
                print("Loaded:", loaded.watchers)
            }
        } catch {
            print("Archive error:", error)
        }

        return serializer.serialize(report)
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: "person.2")
                .imageScale(.large)
                .foregroundStyle(.tint)

            Text("Hi, I'm WatcherTracker.")
                .font(.title2)

            Text("""
            WatcherTracker is a SwiftUI macOS utility for cleaning, archiving, \
            and comparing DeviantArt watcher lists.
            """)

            Divider()

            Text("Test Report")
                .font(.headline)

            Text(reportText)
                .font(.system(.body, design: .monospaced))
        }
        .padding()
        .frame(minWidth: 500, minHeight: 400)
    }
}

#Preview {
    ContentView()
}