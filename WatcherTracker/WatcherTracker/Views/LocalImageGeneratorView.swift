//
//  LocalImageGeneratorView.swift
//  WatcherTracker
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct LocalImageGeneratorView: View {

    @Environment(\.openWindow)
    private var openWindow

    // MARK: - Generator Settings

    @State
    private var prompt = ""

    @State
    private var negativePrompt =
        "blurry, low quality, distorted"

    @State
    private var selectedSize =
        LocalImageSize.square

    @State
    private var steps = 30

    @State
    private var guidanceScale = 5.5

    @State
    private var seedText = ""

    // MARK: - Server / Generation State

    @State
    private var serverInfo: LocalAIServerInfo?

    @State
    private var generatedImage:
        GeneratedImageContext?

    @State
    private var isGenerating = false

    @State
    private var errorMessage: String?

    private let client =
        LocalAIClient()

    // MARK: - Body

    var body: some View {

        HSplitView {

            controlsPane
                .frame(
                    minWidth: 420,
                    idealWidth: 460,
                    maxWidth: 520,
                    maxHeight: .infinity,
                    alignment: .topLeading
                )

            previewPane
                .frame(
                    minWidth: 500,
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )
        }
        .frame(
            minWidth: 1000,
            minHeight: 700
        )
        .task {
            await monitorServer()
        }
    }

    // MARK: - Controls Pane

    private var controlsPane: some View {

        VStack(
            alignment: .leading,
            spacing: 16
        ) {

            header

            Divider()

            promptSection

            negativePromptSection

            parameterSection

            if let errorMessage {

                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.callout)
            }

            Spacer()

            generationStatus

            generateButton
        }
        .padding(24)
    }

    // MARK: - Header

    private var header: some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            HStack {

                Label(
                    "Local AI Image Generator",
                    systemImage: "cpu"
                )
                .font(.title2)
                .fontWeight(.semibold)

                Spacer()

                serverStatus
            }

            Text(
                "Generate images locally using Juggernaut XL."
            )
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Server Status

    private var serverStatus: some View {

        HStack(spacing: 6) {

            Circle()
                .frame(
                    width: 8,
                    height: 8
                )
                .foregroundStyle(
                    serverInfo == nil
                    ? .red
                    : serverInfo?.busy == true
                        ? .orange
                        : .green
                )

            Text(serverStatusText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var serverStatusText: String {

        guard let serverInfo else {
            return "Offline"
        }

        if serverInfo.busy {

            if let state =
                serverInfo.state
            {
                return state.capitalized
            }

            return "Busy"
        }

        return "Ready"
    }

    // MARK: - Prompt

    private var promptSection: some View {

        VStack(
            alignment: .leading,
            spacing: 6
        ) {

            Text("Prompt")
                .font(.headline)

            TextEditor(
                text: $prompt
            )
            .font(.body)
            .padding(6)
            .frame(
                minHeight: 150
            )
            .background(
                Color(
                    nsColor:
                        .textBackgroundColor
                )
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 8
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

    // MARK: - Negative Prompt

    private var negativePromptSection:
        some View
    {

        VStack(
            alignment: .leading,
            spacing: 6
        ) {

            Text("Negative Prompt")
                .font(.headline)

            TextEditor(
                text: $negativePrompt
            )
            .font(.body)
            .padding(6)
            .frame(
                minHeight: 80
            )
            .background(
                Color(
                    nsColor:
                        .textBackgroundColor
                )
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 8
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

    // MARK: - Parameters

    private var parameterSection: some View {

        Grid(
            alignment: .leading,
            horizontalSpacing: 14,
            verticalSpacing: 10
        ) {

            GridRow {

                Text("Image Size")
                    .foregroundStyle(.secondary)

                Picker(
                    "",
                    selection: $selectedSize
                ) {

                    ForEach(
                        LocalImageSize.allCases
                    ) { size in

                        Text(size.title)
                            .tag(size)
                    }
                }
                .labelsHidden()
                .frame(width: 180)
            }

            GridRow {

                Text("Steps")
                    .foregroundStyle(.secondary)

                Stepper(
                    "\(steps)",
                    value: $steps,
                    in: 10...60
                )
                .frame(width: 180)
            }

            GridRow {

                Text("Guidance")
                    .foregroundStyle(.secondary)

                Stepper(
                    String(
                        format: "%.1f",
                        guidanceScale
                    ),
                    value: $guidanceScale,
                    in: 1.0...12.0,
                    step: 0.5
                )
                .frame(width: 180)
            }

            GridRow {

                Text("Seed")
                    .foregroundStyle(.secondary)

                TextField(
                    "Random",
                    text: $seedText
                )
                .frame(width: 180)
            }
        }
    }

    // MARK: - Generation Status

    @ViewBuilder
    private var generationStatus: some View {

        if
            isGenerating ||
            serverInfo?.busy == true
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

                        Text(
                            "Generating"
                        )

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

                    if
                        let currentStep =
                            serverInfo?
                                .currentStep,
                        let totalSteps =
                            serverInfo?
                                .totalSteps
                    {

                        Text(
                            "Step \(currentStep) of \(totalSteps)"
                        )
                        .font(.caption)
                        .foregroundStyle(
                            .secondary
                        )
                    }

                } else {

                    ProgressView()

                    Text(
                        serverInfo?.state?
                            .capitalized
                        ?? "Starting generation…"
                    )
                    .font(.caption)
                    .foregroundStyle(
                        .secondary
                    )
                }
            }
        }
    }

    // MARK: - Generate Button

    private var generateButton: some View {

        HStack {

            if let info = serverInfo {

                VStack(
                    alignment: .leading,
                    spacing: 2
                ) {

                    Text(
                        info.models
                            .first
                        ?? "Juggernaut XL"
                    )
                    .font(.caption)

                    Text(
                        info.backend.uppercased()
                    )
                    .font(.caption2)
                    .foregroundStyle(
                        .secondary
                    )
                }
            }

            Spacer()

            Button(
                "Generate"
            ) {

                generate()
            }
            .buttonStyle(
                .borderedProminent
            )
            .keyboardShortcut(
                .defaultAction
            )
            .disabled(
                !canGenerate
            )
        }
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
            .isEmpty &&
        parsedSeedIsValid
    }

    // MARK: - Preview Pane

    private var previewPane: some View {

        VStack(
            alignment: .leading,
            spacing: 16
        ) {

            HStack {

                Text("Preview")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Button(
                    "Save Image…"
                ) {
                    saveImage()
                }
                .disabled(
                    generatedImage == nil
                )
            }

            Divider()

            previewContent

            if generatedImage != nil {

                Text(
                    "Click the image to open a larger preview."
                )
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )
            }
        }
        .padding(24)
    }

    // MARK: - Preview Content

    @ViewBuilder
    private var previewContent: some View {

        if let generatedImage {

            Button {

                openWindow(
                    value:
                        generatedImage
                )

            } label: {

                AsyncImage(
                    url:
                        generatedImage
                            .imageURL
                ) { phase in

                    switch phase {

                    case .empty:

                        ProgressView()
                            .frame(
                                maxWidth:
                                    .infinity,
                                maxHeight:
                                    .infinity
                            )

                    case .success(
                        let image
                    ):

                        image
                            .resizable()
                            .scaledToFit()
                            .frame(
                                maxWidth:
                                    .infinity,
                                maxHeight:
                                    .infinity
                            )

                    case .failure:

                        ContentUnavailableView(
                            "Unable to Load Image",
                            systemImage:
                                "exclamationmark.triangle"
                        )

                    @unknown default:

                        EmptyView()
                    }
                }
            }
            .buttonStyle(.plain)
            .contentShape(
                Rectangle()
            )
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )

        } else {

            ContentUnavailableView(
                "No Image",
                systemImage: "photo",
                description:
                    Text(
                        "Enter a prompt and generate an image."
                    )
            )
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )
        }
    }

    // MARK: - Generation

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

        let requestedSeed =
            parsedSeed

        let request =
            LocalAIGenerationRequest(
                prompt: cleanPrompt,
                negativePrompt:
                    cleanNegativePrompt,
                width:
                    selectedSize.width,
                height:
                    selectedSize.height,
                steps:
                    steps,
                guidanceScale:
                    guidanceScale,
                seed:
                    requestedSeed
            )

        // Capture the settings now.
        // The user may edit the controls while
        // generation is still running.

        let requestedSteps =
            steps

        let requestedGuidance =
            guidanceScale

        let modelName =
            serverInfo?
                .models.first
            ?? "Juggernaut XL v9"

        let backend =
            serverInfo?
                .backend
                .uppercased()
            ?? "MPS"

        errorMessage =
            nil

        isGenerating =
            true

        Task {

            defer {
                isGenerating =
                    false
            }

            do {

                let response =
                    try await client.generate(
                        request
                    )

                guard
                    let imageURL =
                        client.imageURL(
                            for:
                                response
                        )
                else {

                    throw LocalImageGeneratorError
                        .invalidImageURL
                }

                var parameters: [
                    GeneratedImageParameter
                ] = [

                    .init(
                        name: "Model",
                        value: modelName
                    ),

                    .init(
                        name: "Backend",
                        value: backend
                    ),

                    .init(
                        name: "Size",
                        value:
                            "\(response.width) × \(response.height)"
                    ),

                    .init(
                        name: "Steps",
                        value:
                            "\(requestedSteps)"
                    ),

                    .init(
                        name: "Guidance",
                        value:
                            String(
                                format:
                                    "%.1f",
                                requestedGuidance
                            )
                    ),

                    .init(
                        name: "Seed",
                        value:
                            "\(response.seed)"
                    ),

                    .init(
                        name:
                            "Generation Time",
                        value:
                            String(
                                format:
                                    "%.1f seconds",
                                response
                                    .generationSeconds
                            )
                    )
                ]

                if
                    !cleanNegativePrompt
                        .isEmpty
                {
                    parameters.append(
                        .init(
                            name:
                                "Negative Prompt",
                            value:
                                cleanNegativePrompt
                        )
                    )
                }

                generatedImage =
                    GeneratedImageContext(
                        imageURL:
                            imageURL,
                        provider:
                            "Local AI",
                        prompt:
                            cleanPrompt,
                        parameters:
                            parameters
                    )

                // Put the real seed back into
                // the UI so it can easily be
                // reproduced.

                seedText =
                    "\(response.seed)"

                errorMessage =
                    nil

                await refreshServerInfo()

            } catch {

                errorMessage =
                    "Generation failed: \(error.localizedDescription)"

                await refreshServerInfo()
            }
        }
    }

    // MARK: - Seed

    private var parsedSeed:
        UInt64?
    {

        let value =
            seedText
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )

        guard
            !value.isEmpty
        else {
            return nil
        }

        return UInt64(value)
    }

    private var parsedSeedIsValid:
        Bool
    {

        let value =
            seedText
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )

        return
            value.isEmpty ||
            UInt64(value) != nil
    }

    // MARK: - Server Monitoring

    private func monitorServer() async {

        while !Task.isCancelled {

            await refreshServerInfo()

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

    private func refreshServerInfo()
        async
    {

        do {

            serverInfo =
                try await client.info()

        } catch {

            serverInfo =
                nil
        }
    }

    // MARK: - Save

    @MainActor
    private func saveImage() {

        guard
            let generatedImage
        else {
            return
        }

        let imageURL =
            generatedImage.imageURL

        let panel =
            NSSavePanel()

        panel.title =
            "Save Generated Image"

        panel.prompt =
            "Save"

        panel.nameFieldStringValue =
            imageURL
                .lastPathComponent
                .isEmpty
            ? "generated-image.png"
            : imageURL
                .lastPathComponent

        if
            let type = UTType(
                filenameExtension:
                    imageURL.pathExtension
            )
        {
            panel.allowedContentTypes = [
                type
            ]

        } else {

            panel.allowedContentTypes = [
                .png,
                .jpeg,
                .heic
            ]
        }

        guard
            panel.runModal() == .OK,
            let destinationURL =
                panel.url
        else {
            return
        }

        Task {

            do {

                try await
                    GeneratedImageExporter
                        .export(
                            context:
                                generatedImage,
                            to:
                                destinationURL
                        )

                errorMessage =
                    nil

            } catch {

                errorMessage =
                    error.localizedDescription
            }
        }
    }
}

// MARK: - Image Size Presets

private enum LocalImageSize:
    String,
    CaseIterable,
    Identifiable
{
    case square
    case landscape
    case portrait
    case wide
    case tall

    var id: Self {
        self
    }

    var width: Int {

        switch self {

        case .square:
            return 1024

        case .landscape:
            return 1152

        case .portrait:
            return 896

        case .wide:
            return 1216

        case .tall:
            return 832
        }
    }

    var height: Int {

        switch self {

        case .square:
            return 1024

        case .landscape:
            return 896

        case .portrait:
            return 1152

        case .wide:
            return 832

        case .tall:
            return 1216
        }
    }

    var title: String {

        "\(width) × \(height)"
    }
}

// MARK: - Errors

private enum LocalImageGeneratorError:
    LocalizedError
{
    case invalidImageURL

    var errorDescription: String? {

        switch self {

        case .invalidImageURL:

            return
                "The server returned an invalid image URL."
        }
    }
}

#Preview {
    LocalImageGeneratorView()
}
