//
//  WindowOpenStateTracker.swift
//  WatcherTracker
//
//  Created by Helga Moore on 16/09/2026.
//

import SwiftUI
import AppKit

struct WindowOpenStateTracker: NSViewRepresentable {
    let storageKey: String

    func makeCoordinator() -> Coordinator {
        Coordinator(storageKey: storageKey)
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView()

        DispatchQueue.main.async {
            guard let window = view.window else {
                return
            }

            context.coordinator.attach(to: window)
        }

        return view
    }

    func updateNSView(
        _ nsView: NSView,
        context: Context
    ) {
    }

    static func dismantleNSView(
        _ nsView: NSView,
        coordinator: Coordinator
    ) {
        coordinator.detach()
    }

    final class Coordinator {
        private let storageKey: String

        private weak var window: NSWindow?
        private var closeObserver: NSObjectProtocol?

        init(storageKey: String) {
            self.storageKey = storageKey
        }

        func attach(to window: NSWindow) {
            guard self.window !== window else {
                return
            }

            detach()

            self.window = window

            UserDefaults.standard.set(
                true,
                forKey: storageKey
            )

            closeObserver = NotificationCenter.default.addObserver(
                forName: NSWindow.willCloseNotification,
                object: window,
                queue: .main
            ) { [storageKey] _ in
                UserDefaults.standard.set(
                    false,
                    forKey: storageKey
                )
            }
        }

        func detach() {
            if let closeObserver {
                NotificationCenter.default.removeObserver(
                    closeObserver
                )
            }

            closeObserver = nil
            window = nil
        }

        deinit {
            detach()
        }
    }
}
