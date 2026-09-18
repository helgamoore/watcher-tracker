//
//  ServerLogView.swift
//  AI Server Manager
//
//  Created by Helga Moore on 18/09/2026.
//

import SwiftUI

struct ServerLogView: View {

    @ObservedObject
    var manager: ServerManager

    @State private var logText = ""
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .padding()
            }

            ScrollView {
                Text(logText)
                    .font(
                        .system(
                            .body,
                            design: .monospaced
                        )
                    )
                    .textSelection(.enabled)
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                    .padding()
            }
        }
        .frame(
            minWidth: 800,
            minHeight: 500
        )
        .task {
            await monitorLog()
        }
        .toolbar {
            Button {
                loadLog()
            } label: {
                Label(
                    "Refresh",
                    systemImage: "arrow.clockwise"
                )
            }
        }
    }

    private func monitorLog() async {

        while !Task.isCancelled {

            loadLog()

            try? await Task.sleep(
                for: .seconds(1)
            )
        }
    }

    private func loadLog() {

        guard
            let path = manager.info?.logFile
        else {
            logText = ""
            errorMessage =
                "Server log location is unavailable."
            return
        }

        do {
            logText = try String(
                contentsOfFile: path,
                encoding: .utf8
            )

            errorMessage = nil

        } catch {
            errorMessage =
                "Reading server log failed: \(error.localizedDescription)"
        }
    }
}
