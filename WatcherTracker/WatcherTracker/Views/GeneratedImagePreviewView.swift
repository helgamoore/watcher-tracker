import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct GeneratedImagePreviewView: View {

    let imageURL: URL

    @State
    private var errorMessage: String?

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

                let data: Data

                if imageURL.isFileURL {

                    data =
                        try Data(
                            contentsOf:
                                imageURL
                        )

                } else {

                    let (
                        downloadedData,
                        response
                    ) =
                        try await URLSession.shared
                            .data(
                                from:
                                    imageURL
                            )

                    if
                        let httpResponse =
                            response
                                as? HTTPURLResponse,
                        !(200..<300)
                            .contains(
                                httpResponse
                                    .statusCode
                            )
                    {
                        throw ImageSaveError
                            .downloadFailed
                    }

                    data =
                        downloadedData
                }

                try data.write(
                    to:
                        destinationURL,
                    options:
                        .atomic
                )

                errorMessage =
                    nil

            } catch {

                errorMessage =
                    "Saving image failed: \(error.localizedDescription)"
            }
        }
    }
}

private enum ImageSaveError:
    LocalizedError
{
    case downloadFailed

    var errorDescription: String? {

        switch self {

        case .downloadFailed:
            return
                "The image could not be downloaded."
        }
    }
}
