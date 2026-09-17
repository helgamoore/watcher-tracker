//
//  AppleImagePlaygroundView.swift
//  WatcherTracker
//
//  Created by Helga Moore on 17/09/2026.
//

import SwiftUI
import AppKit
import ImagePlayground
import UniformTypeIdentifiers

struct ImagePlaygroundGeneratorView: View {
    @State private var prompt = ""
    @State private var showingPlayground = false
    @State private var generatedImageURL: URL?

    @State private var selectedStyle: ImagePlaygroundStyle = .illustration
    @State private var errorMessage: String?

    @Environment(\.supportsImagePlayground)
    private var supportsImagePlayground

    private let allowedStyles: [ImagePlaygroundStyle] = [
        .illustration,
        .animation,
        .sketch,
        .externalProvider
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            Text("Image Playground")
                .font(.title2)

            // MARK: Prompt

            Text("Prompt")
                .font(.headline)

            TextEditor(text: $prompt)
                .font(.body)
                .frame(minHeight: 100)
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(.separator)
                }

            // MARK: Controls

            HStack {

                Picker(
                    "Style",
                    selection: $selectedStyle
                ) {
                    Text("Illustration")
                        .tag(ImagePlaygroundStyle.illustration)

                    Text("Animation")
                        .tag(ImagePlaygroundStyle.animation)

                    Text("Sketch")
                        .tag(ImagePlaygroundStyle.sketch)

                    Text("ChatGPT")
                        .tag(ImagePlaygroundStyle.externalProvider)
                }
                .frame(width: 180)

                Spacer()

                Button("Save Image…") {
                    saveImage()
                }
                .disabled(generatedImageURL == nil)

                Button("Generate") {
                    showingPlayground = true
                }
                .keyboardShortcut(.defaultAction)
                .disabled(
                    !supportsImagePlayground ||
                    prompt.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ).isEmpty
                )
            }

            Divider()

            // MARK: Preview

            if let generatedImageURL {

                AsyncImage(url: generatedImageURL) { phase in
                    switch phase {

                    case .empty:
                        ProgressView()

                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()

                    case .failure:
                        ContentUnavailableView(
                            "Unable to Load Image",
                            systemImage: "exclamationmark.triangle"
                        )

                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )

            } else {

                ContentUnavailableView(
                    "No Image",
                    systemImage: "photo",
                    description: Text(
                        "Enter a prompt and generate an image."
                    )
                )
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )
            }

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }
        }
        .padding()
        .frame(
            minWidth: 650,
            minHeight: 650
        )
        .imagePlaygroundSheet(
            isPresented: $showingPlayground,
            concept: prompt,
            sourceImage: nil,
            onCompletion: { url in
                generatedImageURL = url
                errorMessage = nil
            }
        )
        .imagePlaygroundGenerationStyle(
            selectedStyle,
            in: allowedStyles
        )
    }

    // MARK: - Save

    @MainActor
    private func saveImage() {

        guard let generatedImageURL else {
            return
        }

        let panel = NSSavePanel()

        panel.title = "Save Generated Image"
        panel.prompt = "Save"

        panel.nameFieldStringValue =
            generatedImageURL.lastPathComponent.isEmpty
            ? "generated-image.png"
            : generatedImageURL.lastPathComponent

        panel.allowedContentTypes = [
            .png,
            .jpeg,
            .heic
        ]

        guard
            panel.runModal() == .OK,
            let destinationURL = panel.url
        else {
            return
        }

        do {
            let data = try Data(
                contentsOf: generatedImageURL
            )

            try data.write(
                to: destinationURL,
                options: .atomic
            )

            errorMessage = nil

        } catch {
            errorMessage =
                "Saving image error: \(error.localizedDescription)"
        }
    }
}
