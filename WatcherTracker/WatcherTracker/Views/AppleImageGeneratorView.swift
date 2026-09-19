//
//  AppleImageGeneratorView.swift
//  WatcherTracker
//

import SwiftUI
import AppKit
import ImagePlayground
import UniformTypeIdentifiers

struct AppleImageGeneratorView: View {

    @Environment(\.supportsImagePlayground)
    private var supportsImagePlayground

    @Environment(\.openWindow)
    private var openWindow

    @State
    private var prompt = ""

    @State
    private var showingPlayground = false

    @State
    private var generatedImage:
        GeneratedImageContext?

    @State
    private var selectedStyle:
        ImagePlaygroundStyle =
            .illustration

    @State
    private var errorMessage: String?

    // MARK: - Available Styles

    private var allowedStyles:
        [ImagePlaygroundStyle]
    {
        var styles: [
            ImagePlaygroundStyle
        ] = [
            .illustration,
            .animation,
            .sketch,
            .externalProvider
        ]

        if #available(macOS 27.0, *) {
            styles.insert(
                .any,
                at: 0
            )

            styles.insert(
                .emoji,
                at: styles.endIndex - 1
            )
        }
        return styles
    }

    // MARK: - Body

    var body: some View {

        HSplitView {

            controlsPane
                .frame(
                    minWidth: 380,
                    idealWidth: 430,
                    maxWidth: 500,
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
            minWidth: 950,
            minHeight: 620
        )
        .imagePlaygroundSheet(
            isPresented:
                $showingPlayground,
            concept:
                prompt,
            sourceImage:
                nil,
            onCompletion: { url in

                generatedImage =
                    GeneratedImageContext(
                        imageURL: url,
                        provider:
                            "Apple Image Playground",
                        prompt:
                            prompt
                                .trimmingCharacters(
                                    in:
                                        .whitespacesAndNewlines
                                ),
                        parameters: [
                            GeneratedImageParameter(
                                name: "Style",
                                value:
                                    styleName(
                                        selectedStyle
                                    )
                            )
                        ]
                    )

                errorMessage =
                    nil
            }
        )
        .imagePlaygroundGenerationStyle(
            selectedStyle,
            in: allowedStyles
        )
    }

    // MARK: - Controls Pane

    private var controlsPane: some View {

        VStack(
            alignment: .leading,
            spacing: 18
        ) {

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Label(
                    "Apple Image Generator",
                    systemImage:
                        "apple.logo"
                )
                .font(.title2)
                .fontWeight(
                    .semibold
                )

                Text(
                    "Generate images using Apple Image Playground."
                )
                .foregroundStyle(
                    .secondary
                )
            }

            Divider()

            // MARK: Prompt

            Text("Prompt")
                .font(.headline)

            TextEditor(
                text: $prompt
            )
            .font(.body)
            .padding(6)
            .frame(
                minHeight: 260
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

            // MARK: Style

            VStack(
                alignment: .leading,
                spacing: 6
            ) {

                Text("Style")
                    .font(.headline)

                Picker(
                    "",
                    selection:
                        $selectedStyle
                ) {

                    if #available(
                        macOS 27.0,
                        *
                    ) {

                        Text("Any")
                            .tag(
                                ImagePlaygroundStyle
                                    .any
                            )
                    }

                    Text("Illustration")
                        .tag(
                            ImagePlaygroundStyle
                                .illustration
                        )

                    Text("Animation")
                        .tag(
                            ImagePlaygroundStyle
                                .animation
                        )

                    Text("Sketch")
                        .tag(
                            ImagePlaygroundStyle
                                .sketch
                        )

                    if #available(
                        macOS 27.0,
                        *
                    ) {

                        Text("Emoji")
                            .tag(
                                ImagePlaygroundStyle
                                    .emoji
                            )
                    }

                    Text(
                        "External Provider"
                    )
                    .tag(
                        ImagePlaygroundStyle
                            .externalProvider
                    )
                }
                .labelsHidden()
                .frame(
                    maxWidth: 220
                )
            }

            if !supportsImagePlayground {

                Label(
                    "Image Playground is not available on this Mac.",
                    systemImage:
                        "exclamationmark.triangle"
                )
                .foregroundStyle(
                    .secondary
                )
            }

            if let errorMessage {

                Text(errorMessage)
                    .foregroundStyle(
                        .red
                    )
            }

            Spacer()

            HStack {

                Spacer()

                Button(
                    "Generate"
                ) {

                    showingPlayground =
                        true
                }
                .buttonStyle(
                    .borderedProminent
                )
                .keyboardShortcut(
                    .defaultAction
                )
                .disabled(
                    !supportsImagePlayground ||
                    prompt
                        .trimmingCharacters(
                            in:
                                .whitespacesAndNewlines
                        )
                        .isEmpty
                )
            }
        }
        .padding(24)
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
                    .fontWeight(
                        .semibold
                    )

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
    private var previewContent:
        some View
    {

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
                systemImage:
                    "photo",
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

    // MARK: - Style Name

    private func styleName(
        _ style:
            ImagePlaygroundStyle
    ) -> String {

        if #available(
            macOS 27.0,
            *
        ) {

            if style == .any {
                return "Any"
            }

            if style == .emoji {
                return "Emoji"
            }
        }

        if style == .illustration {
            return "Illustration"
        }

        if style == .animation {
            return "Animation"
        }

        if style == .sketch {
            return "Sketch"
        }

        if style == .externalProvider {
            return "External Provider"
        }

        return "Unknown"
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

#Preview {
    AppleImageGeneratorView()
}
