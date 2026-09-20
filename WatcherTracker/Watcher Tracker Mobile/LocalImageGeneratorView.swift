//
//  LocalImageGeneratorView.swift
//  WatcherTracker
//
//  Created by Helga Moore on 20/09/2026.
//

import SwiftUI

struct LocalImageGeneratorView: View {

    @State
    private var prompt = ""

    @State
    private var negativePrompt =
        "blurry, low quality, distorted"

    @State
    private var steps = 30

    @State
    private var guidanceScale = 5.5

    @State
    private var seedText = ""

    @State
    private var serverInfo:
        LocalAIServerInfo?

    @State
    private var imageURL: URL?

    @State
    private var isGenerating = false

    @State
    private var errorMessage: String?

    private let client =
        LocalAIClient(
            baseURL:
                URL(
                    string:
                        "http://mini256.local:8765"
                )!
        )

    var body: some View {

        NavigationStack {

            GeometryReader { geometry in

                if geometry.size.width > 800 {

                    HStack(spacing: 0) {

                        controls

                        Divider()

                        preview
                    }

                } else {

                    ScrollView {

                        VStack(spacing: 24) {

                            controls

                            preview
                                .frame(
                                    minHeight: 400
                                )
                        }
                    }
                }
            }
            .navigationTitle(
                "Local AI Generator"
            )
        }
        .task {
            await monitorServer()
        }
    }

    // MARK: Controls

    private var controls: some View {

        ScrollView {

            VStack(
                alignment: .leading,
                spacing: 18
            ) {

                serverStatus

                Text("Prompt")
                    .font(.headline)

                TextEditor(
                    text: $prompt
                )
                .frame(
                    minHeight: 180
                )
                .padding(6)
                .background(
                    .quaternary,
                    in:
                        RoundedRectangle(
                            cornerRadius: 10
                        )
                )

                Text("Negative Prompt")
                    .font(.headline)

                TextEditor(
                    text: $negativePrompt
                )
                .frame(
                    minHeight: 90
                )
                .padding(6)
                .background(
                    .quaternary,
                    in:
                        RoundedRectangle(
                            cornerRadius: 10
                        )
                )

                Stepper(
                    "Steps: \(steps)",
                    value: $steps,
                    in: 10...60
                )

                Stepper(
                    String(
                        format:
                            "Guidance: %.1f",
                        guidanceScale
                    ),
                    value:
                        $guidanceScale,
                    in: 1...12,
                    step: 0.5
                )

                HStack {

                    Text("Seed")

                    Spacer()

                    TextField(
                        "Random",
                        text: $seedText
                    )
                    .keyboardType(
                        .numberPad
                    )
                    .multilineTextAlignment(
                        .trailing
                    )
                    .frame(width: 150)
                }

                if
                    isGenerating ||
                    serverInfo?.busy == true
                {
                    generationProgress
                }

                if let errorMessage {

                    Text(errorMessage)
                        .foregroundStyle(.red)
                }

                Button {

                    generate()

                } label: {

                    Label(
                        "Generate",
                        systemImage:
                            "sparkles"
                    )
                    .frame(
                        maxWidth:
                            .infinity
                    )
                }
                .buttonStyle(
                    .borderedProminent
                )
                .controlSize(.large)
                .disabled(
                    !canGenerate
                )
            }
            .padding(24)
        }
        .frame(
            maxWidth: 480
        )
    }

    // MARK: Preview

    private var preview: some View {

        Group {

            if let imageURL {

                AsyncImage(
                    url: imageURL
                ) { phase in

                    switch phase {

                    case .empty:

                        ProgressView()

                    case .success(
                        let image
                    ):

                        image
                            .resizable()
                            .scaledToFit()

                    case .failure:

                        ContentUnavailableView(
                            "Unable to Load Image",
                            systemImage:
                                "photo.badge.exclamationmark"
                        )

                    @unknown default:

                        EmptyView()
                    }
                }

            } else {

                ContentUnavailableView(
                    "No Image",
                    systemImage: "photo",
                    description:
                        Text(
                            "Enter a prompt and generate an image."
                        )
                )
            }
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        .padding(24)
    }

    // MARK: Server

    private var serverStatus: some View {

        HStack(spacing: 8) {

            Circle()
                .fill(
                    serverInfo == nil
                    ? .red
                    : serverInfo?.busy == true
                        ? .orange
                        : .green
                )
                .frame(
                    width: 10,
                    height: 10
                )

            Text(
                serverInfo == nil
                ? "Server offline"
                : serverInfo?.busy == true
                    ? "Server busy"
                    : "Server ready"
            )

            Spacer()

            Text("mini256.local")
                .foregroundStyle(
                    .secondary
                )
        }
        .font(.subheadline)
    }

    // MARK: Progress

    private var generationProgress:
        some View
    {

        VStack(
            alignment: .leading,
            spacing: 6
        ) {

            if let progress =
                serverInfo?
                    .progressPercent
            {

                ProgressView(
                    value: progress,
                    total: 100
                )

                HStack {

                    Text("Generating")

                    Spacer()

                    Text(
                        "\(Int(progress.rounded()))%"
                    )
                    .monospacedDigit()
                }
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )

            } else {

                ProgressView()
            }
        }
    }

    // MARK: Generate

    private func generate() {

        let cleanPrompt =
            prompt.trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )

        let cleanNegativePrompt =
            negativePrompt
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )

        let request =
            LocalAIGenerationRequest(
                prompt:
                    cleanPrompt,
                negativePrompt:
                    cleanNegativePrompt,
                width: 1024,
                height: 1024,
                steps: steps,
                guidanceScale:
                    guidanceScale,
                seed:
                    parsedSeed
            )

        isGenerating = true
        errorMessage = nil

        Task {

            defer {
                isGenerating = false
            }

            do {

                let response =
                    try await
                        client.generate(
                            request
                        )

                imageURL =
                    client.imageURL(
                        for: response
                    )

                seedText =
                    "\(response.seed)"

            } catch {

                errorMessage =
                    error.localizedDescription
            }
        }
    }

    // MARK: Helpers

    private var parsedSeed:
        UInt64?
    {

        let value =
            seedText.trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )

        guard !value.isEmpty
        else {
            return nil
        }

        return UInt64(value)
    }

    private var canGenerate: Bool {

        serverInfo != nil &&
        serverInfo?.busy != true &&
        !isGenerating &&
        !prompt
            .trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )
            .isEmpty
    }

    // MARK: Monitoring

    private func monitorServer() async {

        while !Task.isCancelled {

            do {

                serverInfo =
                    try await
                        client.info()

            } catch {

                serverInfo = nil
            }

            do {

                try await Task.sleep(
                    for:
                        .seconds(1)
                )

            } catch {

                return
            }
        }
    }
}
