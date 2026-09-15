import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ContentView: View {

    @EnvironmentObject private var appState: AppState
    @Environment(\.openWindow) private var openWindow
    
    @State private var sourceFolderURL: URL?
    @State private var archiveFolderURL: URL?

    @State private var sourceFiles: [URL] = []
    @State private var selectedFile: URL?

    @State private var lastProcessedFileName: String?

    @State private var errorMessage: String?
    
    @State private var folderWatcher = FolderWatcher()

    @AppStorage("deviantArtUsername")
    private var deviantArtUsername = ""
    
    private var watchersURL: URL? {
        guard !deviantArtUsername.isEmpty else {
            return nil
        }

        return URL(
            string: "https://www.deviantart.com/\(deviantArtUsername)/about#watchers"
        )
    }
    
    private let bookmarkStore = BookmarkStore()
    private let service = WatcherTrackerService()
    private let archive = WatcherArchive()
    private let favouritesStore = FavouriteArtistsStore()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {

            header

            Divider()

            sourceFolderSection

            archiveFolderSection

            Divider()

            fileSelectionSection

            Spacer()

            statusSection

            bottomBar
        }
        .padding(24)
        .frame(
            minWidth: 650,
            minHeight: 520
        )
        .onAppear {
            restoreState()
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {

            Label(
                "WatcherTracker",
                systemImage: "person.2"
            )
            .font(.title2)

            Text(
                "Import and archive DeviantArt watcher lists."
            )
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Source Folder

    private var sourceFolderSection: some View {
        HStack {

            VStack(alignment: .leading, spacing: 4) {

                Text("Source folder")
                    .font(.headline)

                Text(
                    sourceFolderURL?.path
                    ?? "No source folder selected"
                )
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
            }

            Spacer()

            Button("Select…") {
                chooseSourceFolder()
            }
        }
    }

    // MARK: - Archive Folder

    private var archiveFolderSection: some View {
        HStack {

            VStack(alignment: .leading, spacing: 4) {

                Text("Archive folder")
                    .font(.headline)

                Text(
                    archiveFolderURL?.path
                    ?? "No archive folder selected"
                )
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
            }

            Spacer()

            Button("Select…") {
                chooseArchiveFolder()
            }
        }
    }

    // MARK: - File Selection

    private var fileSelectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {

            Text("Select file for import")
                .font(.headline)

            List(
                sourceFiles,
                id: \.self,
                selection: $selectedFile
            ) { file in

                Text(file.lastPathComponent)
                    .tag(file)
            }
            .frame(minHeight: 180)
            .disabled(sourceFolderURL == nil)

            if sourceFiles.isEmpty,
               sourceFolderURL != nil {

                Text("No files found in source folder.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Status

    @ViewBuilder
    private var statusSection: some View {

        if let lastProcessedFileName {

            Text(
                "Last processed file: \(lastProcessedFileName)"
            )
            .foregroundStyle(.secondary)
        }

        if let lastReport = appState.lastReport {
            Text(
                "Last result: \(lastReport.total) watchers, " +
                "\(lastReport.added.count) added, " +
                "\(lastReport.removed.count) removed."
            )
            .foregroundStyle(.secondary)
        }

        if let errorMessage {

            Text(errorMessage)
                .foregroundStyle(.red)
        }
    }

    // MARK: - Bottom Bar

    private func openDeviantArtProfile() {
        guard let url = watchersURL else {
            return
        }

        NSWorkspace.shared.open(url)
    }

    private var bottomBar: some View {
        HStack {

            Button {
                openDeviantArtProfile()
            } label: {
                HStack(spacing: 6) {
                    Image("DeviantArtLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)

                    Text("Go to DA profile")
                }
            }
            .disabled(deviantArtUsername.isEmpty)

            Spacer()

            Button("Latest report") {
                openWindow(id: "report")
            }
            .disabled(appState.lastReport == nil)

            Button("Current watchers") {
                openWindow(id: "watchers")
            }
            .disabled(appState.currentSnapshot == nil)
            
            Button {
                openWindow(id: "favourites")
            } label: {
                Label(
                    "Favourites",
                    systemImage: "star.fill"
                )
            }
            
            Button("Process") {
                processSelectedFile()
            }
            .keyboardShortcut(.defaultAction)
            .disabled(!canProcess)
        }
    }

    // MARK: - Processing State

    private var canProcess: Bool {
        sourceFolderURL != nil &&
        archiveFolderURL != nil &&
        selectedFile != nil
    }

    // MARK: - Source Folder Selection

    private func chooseSourceFolder() {

        let panel = NSOpenPanel()

        panel.title = "Choose Source Folder"
        panel.prompt = "Select"

        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false

        if let sourceFolderURL {
            panel.directoryURL = sourceFolderURL
        }

        guard
            panel.runModal() == .OK,
            let url = panel.url
        else {
            return
        }

        do {
            try bookmarkStore.saveSourceFolder(url)

            sourceFolderURL = url
            errorMessage = nil

            refreshSourceFiles()
            startFolderWatcher()

        } catch {
            errorMessage = "Choosing source folder error: \(error.localizedDescription)"
        }
    }

    // MARK: - Archive Folder Selection

    private func chooseArchiveFolder() {

        let panel = NSOpenPanel()

        panel.title = "Choose Archive Folder"
        panel.prompt = "Select"

        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false

        if let archiveFolderURL {
            panel.directoryURL = archiveFolderURL
        }

        guard
            panel.runModal() == .OK,
            let url = panel.url
        else {
            return
        }

        do {
            try bookmarkStore.saveArchiveFolder(url)

            archiveFolderURL = url
            errorMessage = nil

        } catch {
            errorMessage = "Choosing archive folder error: \(error.localizedDescription)"
        }
    }

    // MARK: - Source Files

    private func refreshSourceFiles() {

        guard let sourceFolderURL else {
            sourceFiles = []
            selectedFile = nil
            return
        }

        let accessGranted =
            sourceFolderURL.startAccessingSecurityScopedResource()

        defer {
            if accessGranted {
                sourceFolderURL.stopAccessingSecurityScopedResource()
            }
        }

        do {

            let files = try FileManager.default.contentsOfDirectory(
                at: sourceFolderURL,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )

            sourceFiles = files
                .filter {
                    !$0.hasDirectoryPath &&
                    $0.pathExtension.lowercased() == "txt"
                }
                .sorted {
                    $0.lastPathComponent
                        .localizedCaseInsensitiveCompare(
                            $1.lastPathComponent
                        ) == .orderedAscending
                }

            restorePreviousSelection()

            errorMessage = nil

        } catch {
            
            sourceFiles = []
            selectedFile = nil
            errorMessage = "Refreshing source files error: \(error.localizedDescription)"
        }
    }

    private func restorePreviousSelection() {

        guard let lastProcessedFileName else {
            selectedFile = nil
            return
        }

        selectedFile = sourceFiles.first {
            $0.lastPathComponent == lastProcessedFileName
        }
    }

    // MARK: - Process

    private func processSelectedFile() {

        guard
            let selectedFile,
            let archiveFolderURL
        else {
            return
        }

        do {

            let report = try service.process(
                sourceURL: selectedFile,
                archiveFolderURL: archiveFolderURL
            )

            let processedFileName =
                selectedFile.lastPathComponent

            lastProcessedFileName =
                processedFileName

            bookmarkStore.saveLastProcessedFileName(
                processedFileName
            )

            appState.lastReport = report
            openWindow(id: "report")
            errorMessage = nil

            loadCurrentSnapshot()
            
            refreshSourceFiles()

        } catch {
            errorMessage = "Processing selected file error: \(error.localizedDescription)"
        }
    }

    // MARK: - Restore

    private func restoreState() {
        sourceFolderURL =
            bookmarkStore.loadSourceFolder()

        archiveFolderURL =
            bookmarkStore.loadArchiveFolder()

        lastProcessedFileName =
            bookmarkStore.loadLastProcessedFileName()

        refreshSourceFiles()
        startFolderWatcher()

        loadLatestReport()
        loadCurrentSnapshot()
        loadFavourites()
    }
    
    private func loadLatestReport() {
        guard let archiveFolderURL else {
            return
        }

        let accessGranted =
            archiveFolderURL.startAccessingSecurityScopedResource()

        defer {
            if accessGranted {
                archiveFolderURL.stopAccessingSecurityScopedResource()
            }
        }

        do {
            guard let reportURL =
                try archive.latestReportURL(
                    in: archiveFolderURL
                )
            else {
                appState.lastReport = nil
                return
            }

            appState.lastReport =
                try archive.loadReport(
                    from: reportURL
                )

            errorMessage = nil

        } catch {
            errorMessage = "Load latest report error: \(error.localizedDescription)"
        }
    }
    
    private func startFolderWatcher() {
        guard let sourceFolderURL else {
            folderWatcher.stop()
            return
        }

        folderWatcher.start(
            watching: sourceFolderURL
        ) {
            refreshSourceFiles()
        }
    }
    
    private func loadCurrentSnapshot() {
        guard let archiveFolderURL else {
            appState.currentSnapshot = nil
            return
        }

        let accessGranted =
            archiveFolderURL.startAccessingSecurityScopedResource()

        defer {
            if accessGranted {
                archiveFolderURL.stopAccessingSecurityScopedResource()
            }
        }

        do {
            guard let snapshotURL =
                try archive.latestSnapshotURL(
                    in: archiveFolderURL
                )
            else {
                appState.currentSnapshot = nil
                return
            }

            appState.currentSnapshot =
                try archive.loadSnapshot(
                    from: snapshotURL
                )

            errorMessage = nil

        } catch {
            errorMessage = "Load current snapshot error: \(error.localizedDescription)"
        }
    }
    
    private func loadFavourites() {
        guard let archiveFolderURL else {
            appState.favourites = []
            return
        }

        let accessGranted =
            archiveFolderURL.startAccessingSecurityScopedResource()

        defer {
            if accessGranted {
                archiveFolderURL.stopAccessingSecurityScopedResource()
            }
        }

        do {
            appState.favourites = try favouritesStore.load(
                from: archiveFolderURL
            )

            errorMessage = nil

        } catch {
            errorMessage =
                "Loading favourites error: \(error.localizedDescription)"
        }
    }
}

#Preview {
    ContentView()
}
