import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var sourceURL: URL?
    @State private var archiveFolderURL: URL?
    @State private var report: WatcherReport?
    @State private var errorMessage: String?
    @State private var sourceFileName: String?
    
    private let service = WatcherTrackerService()
    private let bookmarkStore = BookmarkStore()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header

            Divider()

            sourceSection
            archiveSection

            processButton

            if let report {
                Divider()
                reportSection(report)
            }

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }
        }
        .padding(24)
        .frame(minWidth: 600, minHeight: 420)
        .onAppear {
            archiveFolderURL = bookmarkStore.loadArchiveFolder()
            sourceFileName = bookmarkStore.loadSourceFileName()
            sourceURL = bookmarkStore.loadSourceFile()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("WatcherTracker", systemImage: "person.2")
                .font(.title2)

            Text("Import, archive, and compare DeviantArt watcher lists.")
                .foregroundStyle(.secondary)
        }
    }

    private var sourceSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Source file")
                    .font(.headline)

                Text(sourceURL?.lastPathComponent ?? sourceFileName ?? "No file selected")
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            Button("Choose…") {
                chooseSourceFile()
            }
        }
    }

    private var archiveSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Archive folder")
                    .font(.headline)

                Text(archiveFolderURL?.path ?? "No folder selected")
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            Button("Choose…") {
                chooseArchiveFolder()
            }
        }
    }

    private var processButton: some View {
        HStack {
            Spacer()

            Button("Process") {
                process()
            }
            .keyboardShortcut(.defaultAction)
            //.disabled(sourceURL == nil || archiveFolderURL == nil)
        }
    }

    private func reportSection(_ report: WatcherReport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Report")
                .font(.headline)

            HStack(spacing: 24) {
                Label(
                    "\(report.added.count) added",
                    systemImage: "plus.circle"
                )

                Label(
                    "\(report.removed.count) removed",
                    systemImage: "minus.circle"
                )

                Label(
                    "\(report.total) total",
                    systemImage: "person.2"
                )
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if !report.added.isEmpty {
                        Text("Added")
                            .font(.headline)

                        ForEach(report.added, id: \.self) { watcher in
                            Text("+ \(watcher)")
                                .font(.system(.body, design: .monospaced))
                        }
                    }

                    if !report.removed.isEmpty {
                        Text("Removed")
                            .font(.headline)

                        ForEach(report.removed, id: \.self) { watcher in
                            Text("- \(watcher)")
                                .font(.system(.body, design: .monospaced))
                        }
                    }

                    if report.added.isEmpty && report.removed.isEmpty {
                        Text("No changes.")
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
            }
            .frame(maxHeight: 220)
        }
    }

    private func chooseSourceFile() {
        let panel = NSOpenPanel()

        panel.title = "Choose Watcher List"
        panel.prompt = "Choose"

        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.plainText]

        if let previousFolder = bookmarkStore.loadSourceFolder() {
            panel.directoryURL = previousFolder
        }

        if panel.runModal() == .OK,
           let url = panel.url {

            sourceURL = url
            errorMessage = nil

            let fileName = url.lastPathComponent
            sourceFileName = fileName

            do {
                try bookmarkStore.saveSourceFile(url)

                bookmarkStore.saveSourceFolder(
                    url.deletingLastPathComponent()
                )

                bookmarkStore.saveSourceFileName(fileName)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func chooseArchiveFolder() {
        let panel = NSOpenPanel()

        panel.title = "Choose Archive Folder"
        panel.prompt = "Choose"

        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false

        if let previousFolder = bookmarkStore.loadArchiveFolder() {
            panel.directoryURL = previousFolder
        }

        if panel.runModal() == .OK,
           let url = panel.url {

            archiveFolderURL = url
            errorMessage = nil

            do {
                try bookmarkStore.saveArchiveFolder(url)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    /*
    private func restoreSourceFile() {
        guard
            let folder = bookmarkStore.loadSourceFolder(),
            let fileName = bookmarkStore.loadSourceFileName()
        else {
            sourceURL = nil
            return
        }

        let url = folder.appendingPathComponent(fileName)

        if FileManager.default.fileExists(atPath: url.path) {
            sourceURL = url
        } else {
            sourceURL = nil
        }
    }
    */
    
    private func process() {
        guard
            let sourceURL,
            let archiveFolderURL
        else {
            return
        }

        do {
            report = try service.process(
                sourceURL: sourceURL,
                archiveFolderURL: archiveFolderURL
            )

            bookmarkStore.clearSourceFile()
            self.sourceURL = nil
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    ContentView()
}
