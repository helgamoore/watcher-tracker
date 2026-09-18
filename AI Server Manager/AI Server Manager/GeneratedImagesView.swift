//
//  GeneratedImagesView.swift
//  AI Server Manager
//
//  Created by Helga Moore on 18/09/2026.
//

import SwiftUI

struct GeneratedImagesView: View {

    @ObservedObject
    var manager: ServerManager

    @State private var selectedFile:
        GeneratedImageFile?

    @State private var confirmDeleteAll =
        false

    var body: some View {
        HSplitView {
            VStack(spacing: 0) {
                imageList
                Spacer(minLength: 0)
            }
            .frame(
                minWidth: 300,
                idealWidth: 340,
                maxHeight: .infinity,
                alignment: .top
            )

            VStack(spacing: 0) {
                preview
                Spacer(minLength: 0)
            }
            .frame(
                minWidth: 500,
                maxHeight: .infinity,
                alignment: .top
            )
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .top
        )
        .task {
            await manager
                .refreshGeneratedFiles()
        }
        .toolbar {
            ToolbarItemGroup {

                Button {
                    Task {
                        await manager
                            .refreshGeneratedFiles()
                    }
                } label: {
                    Label(
                        "Refresh",
                        systemImage: "arrow.clockwise"
                    )
                }

                Button {
                    guard let selectedFile
                    else {
                        return
                    }

                    Task {
                        await manager
                            .deleteGeneratedFile(
                                selectedFile
                            )

                        self.selectedFile =
                            nil
                    }

                } label: {
                    Label(
                        "Delete",
                        systemImage: "trash"
                    )
                }
                .disabled(
                    selectedFile == nil
                )

                Button(
                    role: .destructive
                ) {
                    confirmDeleteAll = true

                } label: {
                    Label(
                        "Delete All",
                        systemImage:
                            "trash.slash"
                    )
                }
                .disabled(
                    manager.generatedFiles
                        .isEmpty
                )
            }
        }
        .confirmationDialog(
            "Delete all generated images?",
            isPresented:
                $confirmDeleteAll
        ) {
            Button(
                "Delete All",
                role: .destructive
            ) {
                Task {
                    await manager
                        .deleteAllGeneratedFiles()

                    selectedFile = nil
                }
            }

            Button(
                "Cancel",
                role: .cancel
            ) {
            }
        }
    }

    private var imageList: some View {
        List(
            manager.generatedFiles,
            selection: $selectedFile
        ) { file in
            VStack(
                alignment: .leading,
                spacing: 4
            ) {
                Text(file.filename)
                    .lineLimit(1)

                Text(
                    ByteCountFormatter.string(
                        fromByteCount: file.sizeBytes,
                        countStyle: .file
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .tag(file)
        }
    }

    @ViewBuilder
    private var preview: some View {

        if let selectedFile,
           let url =
            manager.imageURL(
                for: selectedFile
            ) {

            VStack(spacing: 12) {

                AsyncImage(url: url) {
                    phase in

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
                            systemImage:
                                "exclamationmark.triangle"
                        )

                    @unknown default:
                        EmptyView()
                    }
                }

                Text(
                    selectedFile.filename
                )
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )
            }
            .padding()

        } else {

            ContentUnavailableView(
                "Select an Image",
                systemImage: "photo",
                description: Text(
                    "Choose a generated image from the list."
                )
            )
        }
    }
}
