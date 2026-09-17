//
//  WindowFrameAutosaver.swift
//  WatcherTracker
//
//  Created by Helga Moore on 16/09/2026.
//

import SwiftUI
import AppKit

struct WindowFrameAutosaver: NSViewRepresentable {
    let name: String

    func makeNSView(context: Context) -> NSView {
        let view = NSView()

        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.setFrameAutosaveName(name)
        }

        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
    }
}
