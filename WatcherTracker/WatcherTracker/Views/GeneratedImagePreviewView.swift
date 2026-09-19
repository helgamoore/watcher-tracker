import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - Generated Image Metadata

struct GeneratedImageParameter:
    Codable,
    Hashable
{
    let name: String
    let value: String
}

struct GeneratedImageContext:
    Codable,
    Hashable
{
    let imageURL: URL
    let provider: String
    let prompt: String
    let parameters: [GeneratedImageParameter]
}

// MARK: - Preview

struct GeneratedImagePreviewView: View {

    let context: GeneratedImageContext

    @State
    private var errorMessage: String?

    private var imageURL: URL {
        context.imageURL
    }

    var body: some View {

        VStack(spacing: 0) {

            Button {
                saveImage()
            } label: {

                AsyncImage(
                    url: imageURL
                ) { phase in

                    switch phase {

                    case .empty:

                        ProgressView()

                    case .success(let image):

                        image
                            .resizable()
                            .scaledToFit()
                            .padding(20)

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
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )
                .contentShape(
                    Rectangle()
                )
            }
            .buttonStyle(.plain)
            .help(
                "Click the image to save it"
            )

            if let errorMessage {

                Divider()

                Text(errorMessage)
                    .foregroundStyle(.red)
                    .padding(10)
            }
        }
        .frame(
            minWidth: 600,
            minHeight: 600
        )
    }

    // MARK: - Save

    @MainActor
    private func saveImage() {

        let panel =
            NSSavePanel()

        panel.title =
            "Save Generated Image"

        panel.prompt =
            "Save"

        panel.nameFieldStringValue =
            imageURL.lastPathComponent.isEmpty
            ? "generated-image.png"
            : imageURL.lastPathComponent

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

                try await GeneratedImageExporter.export(
                    context: context,
                    to: destinationURL
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

// MARK: - Shared Exporter

enum GeneratedImageExporter {

    static func export(
        context: GeneratedImageContext,
        to destinationURL: URL
    ) async throws {

        let data =
            try await loadImageData(
                from: context.imageURL
            )

        try data.write(
            to: destinationURL,
            options: .atomic
        )

        do {

            try saveMarkdown(
                context: context,
                beside: destinationURL
            )

        } catch {

            throw GeneratedImageExportError
                .metadataSaveFailed(
                    error
                )
        }
    }

    // MARK: Image Data

    private static func loadImageData(
        from url: URL
    ) async throws -> Data {

        if url.isFileURL {

            return try Data(
                contentsOf: url
            )
        }

        let (
            data,
            response
        ) =
            try await URLSession.shared
                .data(from: url)

        if
            let httpResponse =
                response
                    as? HTTPURLResponse,
            !(200..<300)
                .contains(
                    httpResponse.statusCode
                )
        {
            throw GeneratedImageExportError
                .downloadFailed
        }

        return data
    }

    // MARK: Markdown

    private static func saveMarkdown(
        context: GeneratedImageContext,
        beside imageURL: URL
    ) throws {

        let markdownURL =
            imageURL
                .deletingPathExtension()
                .appendingPathExtension(
                    "md"
                )

        let imageName =
            imageURL.lastPathComponent

        let linkName =
            imageName
                .addingPercentEncoding(
                    withAllowedCharacters:
                        .urlPathAllowed
                )
            ?? imageName

        var markdown = """
        # \(imageName)

        ## Parameters

        - Provider: \(context.provider)
        """

        for parameter
            in context.parameters
        {

            markdown +=
                "\n- \(parameter.name): \(clean(parameter.value))"
        }

        markdown += """


        ## Prompt

        \(context.prompt)

        ## Image

        ![\(imageName)](\(linkName))

        """

        try markdown.write(
            to: markdownURL,
            atomically: true,
            encoding: .utf8
        )
    }

    private static func clean(
        _ value: String
    ) -> String {

        value
            .replacingOccurrences(
                of: "\n",
                with: " "
            )
            .replacingOccurrences(
                of: "\r",
                with: " "
            )
    }
}

// MARK: - Export Errors

private enum GeneratedImageExportError:
    LocalizedError
{
    case downloadFailed
    case metadataSaveFailed(Error)

    var errorDescription: String? {

        switch self {

        case .downloadFailed:

            return
                "The image could not be downloaded."

        case .metadataSaveFailed(
            let error
        ):

            return
                "The image was saved, but the Markdown metadata file could not be created: \(error.localizedDescription)"
        }
    }
}
