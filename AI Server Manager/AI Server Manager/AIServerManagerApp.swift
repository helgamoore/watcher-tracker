//
//  AIServerManagerApp.swift
//  AI Server Manager
//
//  Created by Helga Moore on 18/09/2026.
//

import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(
        _ notification: Notification
    ) {
        let bundleIdentifier =
            Bundle.main.bundleIdentifier

        guard let bundleIdentifier else {
            return
        }

        let runningInstances =
            NSRunningApplication.runningApplications(
                withBundleIdentifier: bundleIdentifier
            )

        if runningInstances.count > 1 {
            NSApp.terminate(nil)
        }
    }
}

@main
struct AIServerManagerApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self)
    private var appDelegate

    @StateObject
    private var manager =
        ServerManager()

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

        Window(
            "Generated Images",
            id: "generated-images"
        ) {
            GeneratedImagesView(
                manager: manager
            )
        }
        
        Window(
            "Server Log",
            id: "server-log"
        ) {
            ServerLogView(
                manager: manager
            )
        }
    }
}
