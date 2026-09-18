//
//  ServerMenuView.swift
//  AI Server Manager
//
//  Created by Helga Moore on 18/09/2026.
//

import SwiftUI
import AppKit

struct ServerMenuView: View {

    @ObservedObject
    var manager: ServerManager

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            header

            Divider()

            statusSection

            if manager.state == .busy {
                Divider()
                generationSection
            }

            if let errorMessage =
                manager.errorMessage {

                Divider()

                Label(
                    errorMessage,
                    systemImage:
                        "exclamationmark.triangle"
                )
                .foregroundStyle(.red)
                .font(.caption)
            }

            Divider()

            actions
        }
        .padding(16)
        .frame(width: 420)
    }

    private var header: some View {
        HStack {

            Image(
                systemName:
                    manager.state.systemImage
            )
            .font(.title2)

            VStack(
                alignment: .leading,
                spacing: 2
            ) {
                Text("Local AI Server")
                    .font(.headline)

                Text(manager.state.title)
                    .foregroundStyle(
                        .secondary
                    )
            }

            Spacer()

            if let progress =
                manager.info?
                    .progressPercent,
               manager.state == .busy {

                Text("\(progress)%")
                    .font(.headline)
                    .monospacedDigit()
            }
        }
    }

    @ViewBuilder
    private var statusSection: some View {

        if let info = manager.info {

            Grid(
                alignment: .leading,
                horizontalSpacing: 12,
                verticalSpacing: 6
            ) {

                statusRow(
                    "Server",
                    info.name
                )

                statusRow(
                    "Version",
                    info.version
                )

                statusRow(
                    "Backend",
                    info.backend.uppercased()
                )

                statusRow(
                    "Model",
                    info.models.joined(
                        separator: ", "
                    )
                )

                statusRow(
                    "Model loaded",
                    info.modelLoaded
                        ? "Yes"
                        : "No"
                )

                if let state = info.state {
                    statusRow(
                        "Operation",
                        state
                    )
                }
            }

        } else {

            Text(
                "The AI server is not available."
            )
            .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var generationSection: some View {

        if let info = manager.info {

            VStack(
                alignment: .leading,
                spacing: 10
            ) {

                if let progress =
                    info.progressPercent {

                    ProgressView(
                        value:
                            Double(progress),
                        total: 100
                    )

                    HStack {
                        Text(
                            "Generation progress"
                        )

                        Spacer()

                        Text(
                            "\(progress)%"
                        )
                        .monospacedDigit()
                    }
                    .font(.caption)
                }

                if let prompt = info.prompt {

                    VStack(
                        alignment: .leading,
                        spacing: 3
                    ) {
                        Text("Prompt")
                            .font(.caption)
                            .foregroundStyle(
                                .secondary
                            )

                        Text(prompt)
                            .textSelection(
                                .enabled
                            )
                    }
                }

                Grid(
                    alignment: .leading,
                    horizontalSpacing: 12,
                    verticalSpacing: 5
                ) {

                    if let width = info.width,
                       let height = info.height {

                        statusRow(
                            "Size",
                            "\(width) × \(height)"
                        )
                    }

                    if let steps = info.steps {

                        statusRow(
                            "Steps",
                            "\(steps)"
                        )
                    }

                    if let guidance =
                        info.guidanceScale {

                        statusRow(
                            "Guidance",
                            String(
                                format: "%.1f",
                                guidance
                            )
                        )
                    }

                    if let seed = info.seed {

                        statusRow(
                            "Seed",
                            "\(seed)"
                        )
                    }

                    if let filename =
                        info.expectedFilename {

                        statusRow(
                            "File",
                            filename
                        )
                    }
                }
            }
        }
    }

    private func statusRow(
        _ title: String,
        _ value: String
    ) -> some View {

        GridRow {

            Text(title)
                .foregroundStyle(
                    .secondary
                )

            Text(value)
                .textSelection(.enabled)
        }
    }

    private var actions: some View {
        VStack(spacing: 8) {

            HStack {

                Button("Start Server") {
                    manager.startServer()
                }
                .disabled(
                    manager.state != .stopped &&
                    manager.state != .unavailable
                )

                Button("Stop Server") {
                    manager.stopServer()
                }
                .disabled(
                    manager.state == .stopped
                )

                Spacer()

                Button("Open Swagger") {
                    manager.openSwagger()
                }
                .disabled(
                    manager.state == .stopped
                )
            }

            HStack {

                Button("Refresh") {
                    Task {
                        await manager.refreshStatus()
                    }
                }

                Spacer()

                Button("Quit Server Manager") {
                    NSApplication.shared.terminate(
                        nil
                    )
                }
            }
        }
    }
}
