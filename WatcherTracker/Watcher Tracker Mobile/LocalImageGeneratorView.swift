//
//  LocalImageGeneratorView.swift
//  WatcherTracker
//
//  Created by Helga Moore on 20/09/2026.
//

import SwiftUI
import UIKit

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
    private var generatedImage:
        GeneratedLocalImage?

    @State
    private var showingFullScreenPreview =
        false

    @State
    private var exportPackage:
        ExportPackage?

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
        .fullScreenCover(
            isPresented:
                $showingFullScreenPreview
        ) {

            if let generatedImage {

                FullScreenImageView(
                    imageURL:
                        generatedImage
                            .imageURL,
                    onSave: {
                        saveGeneratedImage()
                    }
                )
            }
        }
        .sheet(
            item:
                $exportPackage
        ) { package in

            DocumentExporter(
                urls:
                    package.urls
            )
        }
    }

    // MARK: - Controls

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

    // MARK: - Preview

    private var preview: some View {

        VStack(spacing: 16) {

            if let generatedImage {

                Button {

                    showingFullScreenPreview =
                        true

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
                                    "photo.badge.exclamationmark"
                            )

                        @unknown default:

                            EmptyView()
                        }
                    }
                }
                .buttonStyle(.plain)
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )

                HStack {

                    Text(
                        "Tap the image for full-screen preview."
                    )
                    .font(.caption)
                    .foregroundStyle(
                        .secondary
                    )

                    Spacer()

                    Button {

                        saveGeneratedImage()

                    } label: {

                        Label(
                            "Save to Files",
                            systemImage:
                                "folder"
                        )
                    }
                    .buttonStyle(
                        .borderedProminent
                    )
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
                .frame(
                    maxWidth:
                        .infinity,
                    maxHeight:
                        .infinity
                )
            }
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        .padding(24)
    }

    // MARK: - Server

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

    // MARK: - Progress

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
                    "Starting generation…"
                )
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )
            }
        }
    }

    // MARK: - Generate

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

        let requestedSteps =
            steps

        let requestedGuidance =
            guidanceScale

        let requestedSeed =
            parsedSeed

        let modelName =
            serverInfo?
                .models.first
            ?? "juggernaut-xl-v9"

        let request =
            LocalAIGenerationRequest(
                prompt:
                    cleanPrompt,
                negativePrompt:
                    cleanNegativePrompt,
                width: 1024,
                height: 1024,
                steps:
                    requestedSteps,
                guidanceScale:
                    requestedGuidance,
                seed:
                    requestedSeed
            )

        isGenerating =
            true

        errorMessage =
            nil

        Task {

            defer {

                isGenerating =
                    false
            }

            do {

                let response =
                    try await
                        client.generate(
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

                generatedImage =
                    GeneratedLocalImage(
                        imageURL:
                            imageURL,
                        prompt:
                            cleanPrompt,
                        negativePrompt:
                            cleanNegativePrompt,
                        width:
                            response.width,
                        height:
                            response.height,
                        steps:
                            requestedSteps,
                        guidanceScale:
                            requestedGuidance,
                        seed:
                            response.seed,
                        generationSeconds:
                            response
                                .generationSeconds,
                        model:
                            modelName
                    )

                seedText =
                    "\(response.seed)"

                errorMessage =
                    nil

            } catch {

                errorMessage =
                    error.localizedDescription
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

    private var seedIsValid:
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

    private var canGenerate: Bool {

        serverInfo != nil &&
        serverInfo?.busy != true &&
        !isGenerating &&
        seedIsValid &&
        !prompt
            .trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )
            .isEmpty
    }

    // MARK: - Monitoring

    private func monitorServer() async {

        while !Task.isCancelled {

            do {

                serverInfo =
                    try await
                        client.info()

            } catch {

                serverInfo =
                    nil
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

    // MARK: - Save

    private func saveGeneratedImage() {

        guard
            let generatedImage
        else {
            return
        }

        Task {

            do {

                let package =
                    try await
                        createExportPackage(
                            for:
                                generatedImage
                        )

                exportPackage =
                    package

                errorMessage =
                    nil

            } catch {

                errorMessage =
                    "Export failed: \(error.localizedDescription)"
            }
        }
    }

    private func createExportPackage(
        for image:
            GeneratedLocalImage
    ) async throws -> ExportPackage {

        let (
            imageData,
            response
        ) =
            try await
                URLSession.shared
                    .data(
                        from:
                            image.imageURL
                    )

        guard
            let httpResponse =
                response
                    as? HTTPURLResponse,
            200..<300 ~=
                httpResponse
                    .statusCode
        else {

            throw ExportError
                .imageDownloadFailed
        }

        let imageFilename =
            image.imageURL
                .lastPathComponent
                .isEmpty
            ? "generated-image.png"
            : image.imageURL
                .lastPathComponent

        let baseName =
            URL(
                fileURLWithPath:
                    imageFilename
            )
            .deletingPathExtension()
            .lastPathComponent

        let temporaryFolder =
            FileManager.default
                .temporaryDirectory
                .appendingPathComponent(
                    UUID().uuidString,
                    isDirectory: true
                )

        try FileManager.default
            .createDirectory(
                at:
                    temporaryFolder,
                withIntermediateDirectories:
                    true
            )

        let imageDestination =
            temporaryFolder
                .appendingPathComponent(
                    imageFilename
                )

        try imageData.write(
            to:
                imageDestination,
            options:
                .atomic
        )

        let markdownDestination =
            temporaryFolder
                .appendingPathComponent(
                    baseName
                )
                .appendingPathExtension(
                    "md"
                )

        let markdown =
            markdownText(
                for:
                    image,
                imageFilename:
                    imageFilename
            )

        try markdown.write(
            to:
                markdownDestination,
            atomically:
                true,
            encoding:
                .utf8
        )

        return ExportPackage(
            urls: [
                imageDestination,
                markdownDestination
            ]
        )
    }

    private func markdownText(
        for image:
            GeneratedLocalImage,
        imageFilename:
            String
    ) -> String {

        let linkFilename =
            imageFilename
                .addingPercentEncoding(
                    withAllowedCharacters:
                        .urlPathAllowed
                )
            ?? imageFilename

        var result = """
        # \(imageFilename)

        ## Parameters

        - Provider: Local AI
        - Model: \(image.model)
        - Size: \(image.width) × \(image.height)
        - Steps: \(image.steps)
        - Guidance: \(String(format: "%.1f", image.guidanceScale))
        - Seed: \(image.seed)
        - Generation Time: \(String(format: "%.1f", image.generationSeconds)) seconds
        """

        if
            !image
                .negativePrompt
                .isEmpty
        {

            result +=
                "\n- Negative Prompt: \(image.negativePrompt)"
        }

        result += """


        ## Prompt

        \(image.prompt)

        ## Image

        ![\(imageFilename)](\(linkFilename))

        """

        return result
    }
}

// MARK: - Generated Image

struct GeneratedLocalImage {

    let imageURL: URL

    let prompt: String
    let negativePrompt: String

    let width: Int
    let height: Int

    let steps: Int
    let guidanceScale: Double

    let seed: UInt64

    let generationSeconds: Double

    let model: String
}

// MARK: - Full Screen Preview

struct FullScreenImageView: View {

    let imageURL: URL

    let onSave: () -> Void

    @Environment(\.dismiss)
    private var dismiss

    var body: some View {

        NavigationStack {

            ZStack {

                Color.black
                    .ignoresSafeArea()

                AsyncImage(
                    url:
                        imageURL
                ) { phase in

                    switch phase {

                    case .empty:

                        ProgressView()
                            .tint(.white)

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
                                "photo.badge.exclamationmark"
                        )
                        .foregroundStyle(
                            .white
                        )

                    @unknown default:

                        EmptyView()
                    }
                }
            }
            .toolbar {

                ToolbarItem(
                    placement:
                        .topBarLeading
                ) {

                    Button(
                        "Close"
                    ) {
                        dismiss()
                    }
                }

                ToolbarItem(
                    placement:
                        .topBarTrailing
                ) {

                    Button {

                        onSave()

                    } label: {

                        Image(
                            systemName:
                                "square.and.arrow.down"
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Export Package

struct ExportPackage:
    Identifiable
{

    let id =
        UUID()

    let urls: [URL]
}

// MARK: - Document Picker

struct DocumentExporter:
    UIViewControllerRepresentable
{

    let urls: [URL]

    func makeUIViewController(
        context: Context
    ) -> UIDocumentPickerViewController {

        UIDocumentPickerViewController(
            forExporting:
                urls,
            asCopy:
                true
        )
    }

    func updateUIViewController(
        _ uiViewController:
            UIDocumentPickerViewController,
        context: Context
    ) {
    }
}

// MARK: - Errors

private enum LocalImageGeneratorError:
    LocalizedError
{

    case invalidImageURL

    var errorDescription:
        String?
    {

        switch self {

        case .invalidImageURL:

            return
                "The server returned an invalid image URL."
        }
    }
}

private enum ExportError:
    LocalizedError
{

    case imageDownloadFailed

    var errorDescription:
        String?
    {

        switch self {

        case .imageDownloadFailed:

            return
                "Unable to download the generated image from the server."
        }
    }
}
