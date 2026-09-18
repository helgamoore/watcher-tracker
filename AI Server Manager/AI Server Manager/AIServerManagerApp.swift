//
//  AIServerManagerApp.swift
//  AI Server Manager
//
//  Created by Helga Moore on 18/09/2026.
//

import SwiftUI

@main
struct AIServerManagerApp: App {

    @StateObject
    private var manager = ServerManager()

    var body: some Scene {

        MenuBarExtra {
            ServerMenuView(
                manager: manager
            )
        } label: {

            Label(
                "Local AI Server",
                systemImage:
                    manager.state.systemImage
            )
            .onAppear {
                manager.startMonitoring()
            }
        }
        .menuBarExtraStyle(.window)
    }
}
