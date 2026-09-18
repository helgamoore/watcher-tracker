//
//  TestGenerationView.swift
//  AI Server Manager
//
//  Created by Helga Moore on 18/09/2026.
//

import SwiftUI

struct TestGenerationView: View {

    @ObservedObject
    var manager: ServerManager

    @State private var prompt =
        "A small futuristic server room, cinematic lighting, highly detailed"

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 18
        ) {

            header

            promptEditor

            footer
        }
        .padding(24)
        .frame(
            width: 560,
            height: 340
        )
    }

    private var header: some View {
        HStack(alignment: .top) {

            VStack(
                alignment: .leading,
                spacing: 6
            ) {
                Text("Test Generation")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(
                    "Run a small generation job to verify that the local AI server and model are healthy."
                )
                .foregroundStyle(.secondary)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
            }

            Spacer()

            HStack(spacing: 6) {
                Circle()
                    .frame(
                        width: 8,
                        height: 8
                    )

                Text(
                    manager.state.title
                )
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
        }
    }

    private var promptEditor: some View {
        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            Text("Prompt")
                .font(.headline)

            TextEditor(
                text: $prompt
            )
            .font(
                .system(
                    .body,
                    design: .monospaced
                )
            )
            .padding(8)
            .frame(
                minHeight: 140
            )
            .background(
                RoundedRectangle(
                    cornerRadius: 8
                )
                .fill(
                    Color(
                        nsColor:
                            .textBackgroundColor
                    )
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: 8
                )
                .stroke(
                    Color.secondary
                        .opacity(0.2)
                )
            }
        }
    }

    private var footer: some View {
        HStack {

            VStack(
                alignment: .leading,
                spacing: 3
            ) {

                Text(
                    "512 × 512 · 12 steps · CFG 5.5"
                )
                    .font(.caption)
                    .foregroundStyle(
                        .secondary
                    )

                if manager
                    .testGenerationRunning
                {
                    Text(
                        "Generating test image…"
                    )
                    .font(.caption)
                    .foregroundStyle(
                        .secondary
                    )
                }
            }

            Spacer()

            if manager
                .testGenerationRunning
            {
                ProgressView()
                    .controlSize(.small)
            }

            Button(
                "Generate Test Image"
            ) {
                Task {
                    await manager
                        .generateTestImage(
                            prompt: prompt
                        )
                }
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(
                .defaultAction
            )
            .disabled(
                manager
                    .testGenerationRunning ||
                manager.state == .stopped ||
                manager.state == .busy
            )
        }
    }
}
