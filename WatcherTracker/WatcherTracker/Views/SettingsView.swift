//
//  SettingsView.swift
//  WatcherTracker
//
//  Created by Helga Moore on 14/09/2026.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct SettingsView: View {
    @AppStorage("deviantArtUsername")
    private var deviantArtUsername = ""

    var body: some View {
        Form {
            TextField(
                "DeviantArt username",
                text: $deviantArtUsername
            )
        }
        .padding()
        .frame(width: 400)
    }
}
