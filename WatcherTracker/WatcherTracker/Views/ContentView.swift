import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ContentView: View {

    @EnvironmentObject
    private var appState: AppState

    @Environment(\.openWindow)
    private var openWindow

    @State
    private var sourceFolderURL: URL?

    @State
    private var archiveFolderURL: URL?

    @State
    private var sourceFiles: [URL] = []

    @State
    private var selectedFile: URL?

    @State
    private var lastProcessedFileName: String?

    @State
    private var errorMessage: String?

    @State
    private var isConnectingDeviantArt = false

    @State
    private var deviantArtStatusMessage: String?

    @State
    private var deviantArtErrorMessage: String?

    @State
    private var folderWatcher = FolderWatcher()

    @AppStorage("watchersWindowOpen")
    private var watchersWindowOpen = false

    @AppStorage("favouritesWindowOpen")
    private var favouritesWindowOpen = false

    @AppStorage("reportWindowOpen")
    private var reportWindowOpen = false

    @AppStorage("historyWindowOpen")
    private var historyWindowOpen = false

    @AppStorage("deviantArtUsername")
    private var deviantArtUsername = ""

    private var watchersURL: URL? {
        guard !deviantArtUsername.isEmpty else {
            return nil
        }

        return URL(
            string:
                "https://www.deviantart.com/\(deviantArtUsername)/about#watchers"
        )
    }

    private let deviantArtClientID =
        "73792"

    private let bookmarkStore =
        BookmarkStore()

    private let service =
        WatcherTrackerService()

    private let archive =
        WatcherArchive()

    private let favouritesStore =
        FavouriteArtistsStore()

    // MARK: - Body

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 20
        ) {

            header

            Divider()

            HSplitView {

                deviantArtWorkspace
                    .frame(
                        minWidth: 600,
                        idealWidth: 720,
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: .topLeading
                    )

                imageGenerationWorkspace
                    .frame(
                        minWidth: 280,
                        idealWidth: 320,
                        maxWidth: 380,
                        maxHeight: .infinity,
                        alignment: .topLeading
                    )
            }
        }
        .padding(24)
        .frame(
            minWidth: 1000,
            minHeight: 600
        )
        .onAppear {
            restoreState()

            if watchersWindowOpen {
                openWindow(
                    id: "watchers"
                )
            }

            if favouritesWindowOpen {
                openWindow(
                    id: "favourites"
                )
            }

            if reportWindowOpen {
                openWindow(
                    id: "report"
                )
            }

            if historyWindowOpen {
                openWindow(
                    id: "report-history"
                )
            }
        }
    }

    // MARK: - Header

    private var header: some View {

        VStack(
            alignment: .leading,
            spacing: 4
        ) {

            Label(
                "WatcherTracker",
                systemImage:
                    "square.grid.2x2"
            )
            .font(.title2)

            Text(
                "DeviantArt tools and AI image generation."
            )
            .foregroundStyle(
                .secondary
            )
        }
    }

    // MARK: - DeviantArt Workspace

    private var deviantArtWorkspace: some View {

        VStack(
            alignment: .leading,
            spacing: 16
        ) {

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Label(
                    "DeviantArt",
                    systemImage:
                        "person.2"
                )
                .font(.title3)
                .fontWeight(.semibold)

                Text(
                    "Import watcher lists, review changes, and manage tracked artists."
                )
                .foregroundStyle(
                    .secondary
                )
            }

            Divider()

            sourceFolderSection

            archiveFolderSection

            Divider()

            fileSelectionSection

            Spacer()

            statusSection

            Divider()

            deviantArtActions
        }
        .padding(.trailing, 16)
    }

    // MARK: - Image Generation Workspace

    private var imageGenerationWorkspace: some View {

        VStack(
            alignment: .leading,
            spacing: 16
        ) {

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Label(
                    "Image Generation",
                    systemImage:
                        "photo.on.rectangle.angled"
                )
                .font(.title3)
                .fontWeight(.semibold)

                Text(
                    "Choose an image-generation provider."
                )
                .foregroundStyle(
                    .secondary
                )
            }

            Divider()

            generatorButton(
                title: "Local AI",
                subtitle:
                    "Juggernaut XL · Local server",
                systemImage: "cpu",
                windowID:
                    "local-image-generator"
            )

            generatorButton(
                title: "Apple",
                subtitle:
                    "Apple Image Playground",
                systemImage:
                    "apple.logo",
                windowID:
                    "apple-image-playground"
            )

            generatorButton(
                title: "Gemini",
                subtitle:
                    "Google image generation",
                systemImage:
                    "sparkles",
                windowID:
                    "gemini-image-generator"
            )

            generatorButton(
                title: "ChatGPT",
                subtitle:
                    "OpenAI image generation",
                systemImage:
                    "bubble.left.and.bubble.right",
                windowID:
                    "chatgpt-image-generator"
            )

            Spacer()
        }
        .padding(.leading, 16)
    }

    // MARK: - Generator Button

    private func generatorButton(
        title: String,
        subtitle: String,
        systemImage: String,
        windowID: String
    ) -> some View {

        Button {

            openWindow(
                id: windowID
            )

        } label: {

            HStack(
                spacing: 12
            ) {

                Image(
                    systemName:
                        systemImage
                )
                .font(.title2)
                .frame(
                    width: 30
                )

                VStack(
                    alignment: .leading,
                    spacing: 2
                ) {

                    Text(title)
                        .fontWeight(
                            .medium
                        )

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(
                            .secondary
                        )
                }

                Spacer()

                Image(
                    systemName:
                        "chevron.right"
                )
                .font(.caption)
                .foregroundStyle(
                    .tertiary
                )
            }
            .padding(12)
            .contentShape(
                Rectangle()
            )
            .background {

                RoundedRectangle(
                    cornerRadius: 8
                )
                .fill(
                    Color(
                        nsColor:
                            .controlBackgroundColor
                    )
                )
            }
            .overlay {

                RoundedRectangle(
                    cornerRadius: 8
                )
                .stroke(
                    Color.secondary
                        .opacity(0.15)
                )
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Source Folder

    private var sourceFolderSection: some View {

        HStack {

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text("Source folder")
                    .font(.headline)

                Text(
                    sourceFolderURL?.path
                    ?? "No source folder selected"
                )
                .foregroundStyle(
                    .secondary
                )
                .lineLimit(1)
                .truncationMode(
                    .middle
                )
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

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text("Archive folder")
                    .font(.headline)

                Text(
                    archiveFolderURL?.path
                    ?? "No archive folder selected"
                )
                .foregroundStyle(
                    .secondary
                )
                .lineLimit(1)
                .truncationMode(
                    .middle
                )
            }

            Spacer()

            Button("Select…") {
                chooseArchiveFolder()
            }
        }
    }

    // MARK: - File Selection

    private var fileSelectionSection: some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            Text(
                "Select file for import"
            )
            .font(.headline)

            List(
                sourceFiles,
                id: \.self,
                selection:
                    $selectedFile
            ) { file in

                Text(
                    file.lastPathComponent
                )
                .tag(file)
            }
            .frame(
                minHeight: 180
            )
            .disabled(
                sourceFolderURL == nil
            )

            if sourceFiles.isEmpty,
               sourceFolderURL != nil {

                Text(
                    "No files found in source folder."
                )
                .foregroundStyle(
                    .secondary
                )
            }
        }
    }

    // MARK: - Status

    private var statusSection: some View {

        VStack(
            alignment: .leading,
            spacing: 4
        ) {

            if let lastProcessedFileName {

                Text(
                    "Last processed file: \(lastProcessedFileName)"
                )
                .foregroundStyle(
                    .secondary
                )
            }

            if let lastReport =
                appState.lastReport {

                Text(
                    "Last result: \(lastReport.total) watchers, "
                    + "\(lastReport.added.count) added, "
                    + "\(lastReport.removed.count) removed."
                )
                .foregroundStyle(
                    .secondary
                )
            }

            if let deviantArtStatusMessage {

                Text(deviantArtStatusMessage)
                    .foregroundStyle(
                        .secondary
                    )
            }

            if let deviantArtErrorMessage {

                Text(deviantArtErrorMessage)
                    .foregroundStyle(
                        .red
                    )
            }

            if let errorMessage {

                Text(errorMessage)
                    .foregroundStyle(
                        .red
                    )
            }
        }
    }

    // MARK: - DeviantArt Actions

    private var deviantArtActions: some View {

        VStack(
            spacing: 8
        ) {

            HStack {

                Button {

                    openDeviantArtProfile()

                } label: {

                    HStack(
                        spacing: 6
                    ) {

                        Image(
                            "DeviantArtLogo"
                        )
                        .resizable()
                        .scaledToFit()
                        .frame(
                            width: 16,
                            height: 16
                        )

                        Text(
                            "DA Profile"
                        )
                    }
                }
                .disabled(
                    deviantArtUsername
                        .isEmpty
                )

                Button(
                    "Latest Report"
                ) {
                    openWindow(
                        id: "report"
                    )
                }
                .disabled(
                    appState
                        .lastReport == nil
                )

                Button(
                    "Current Watchers"
                ) {
                    openWindow(
                        id: "watchers"
                    )
                }
                .disabled(
                    appState
                        .currentSnapshot == nil
                )

                Button {

                    connectDeviantArt()

                } label: {

                    if isConnectingDeviantArt {

                        HStack(
                            spacing: 6
                        ) {

                            ProgressView()
                                .controlSize(
                                    .small
                                )

                            Text(
                                "Connecting…"
                            )
                        }

                    } else {

                        Text(
                            "Connect DeviantArt"
                        )
                    }
                }
                .disabled(
                    isConnectingDeviantArt
                )

                Spacer()

                Button(
                    "Process"
                ) {
                    processSelectedFile()
                }
                .buttonStyle(
                    .borderedProminent
                )
                .keyboardShortcut(
                    .defaultAction
                )
                .disabled(
                    !canProcess
                )
            }
        }
    }

    // MARK: - DeviantArt Connection

    private func connectDeviantArt() {

        guard
            !isConnectingDeviantArt
        else {
            return
        }

        isConnectingDeviantArt =
            true

        deviantArtStatusMessage =
            "Connecting to DeviantArt…"

        deviantArtErrorMessage =
            nil

        Task { @MainActor in

            defer {

                isConnectingDeviantArt =
                    false
            }

            do {

                let auth =
                    DeviantArtAuthService(
                        clientID:
                            deviantArtClientID
                    )

                let token =
                    try await auth
                        .authorize()

                print(
                    "Authenticated. Token expires in \(token.expiresIn) seconds."
                )

                deviantArtStatusMessage =
                    "Authenticated with DeviantArt. Validating token…"

                let client =
                    DeviantArtClient(
                        accessToken:
                            token.accessToken
                    )

                let valid =
                    try await client
                        .validateToken()

                print(
                    "DA token valid:",
                    valid
                )

                guard valid
                else {

                    throw DeviantArtConnectionError
                        .invalidToken
                }

                let user =
                    try await client
                        .whoAmI()

                print(
                    "Authenticated DeviantArt user:",
                    user.username
                )

                // Keep the authenticated username in the
                // same setting already used by WatcherTracker.
                deviantArtUsername =
                    user.username

                deviantArtStatusMessage =
                    "Connected as \(user.username). Loading watchers…"

                let page =
                    try await client
                        .watchers(
                            username:
                                user.username
                        )

                print(
                    "Watchers returned:",
                    page.results.count
                )

                print(
                    "Has more:",
                    page.hasMore
                )

                print(
                    "Next offset:",
                    page.nextOffset
                        as Any
                )

                for watcher in
                    page.results.prefix(10)
                {
                    print(
                        watcher.user.username
                    )
                }

                deviantArtStatusMessage =
                    "Connected as \(user.username). "
                    + "First watcher page: \(page.results.count) records."

                deviantArtErrorMessage =
                    nil

            } catch {

                let description =
                    describeDeviantArtError(
                        error
                    )

                print(
                    "DeviantArt error:",
                    description
                )

                deviantArtStatusMessage =
                    nil

                deviantArtErrorMessage =
                    description
            }
        }
    }

    private func describeDeviantArtError(
        _ error: Error
    ) -> String {

        switch error {

        case let DecodingError.keyNotFound(
            key,
            context
        ):

            return
                "DeviantArt decoding error: missing key "
                + "'\(key.stringValue)' at "
                + codingPathDescription(
                    context.codingPath
                )
                + ". "
                + context.debugDescription

        case let DecodingError.valueNotFound(
            type,
            context
        ):

            return
                "DeviantArt decoding error: missing value for "
                + "\(type) at "
                + codingPathDescription(
                    context.codingPath
                )
                + ". "
                + context.debugDescription

        case let DecodingError.typeMismatch(
            type,
            context
        ):

            return
                "DeviantArt decoding error: type mismatch for "
                + "\(type) at "
                + codingPathDescription(
                    context.codingPath
                )
                + ". "
                + context.debugDescription

        case let DecodingError.dataCorrupted(
            context
        ):

            return
                "DeviantArt decoding error at "
                + codingPathDescription(
                    context.codingPath
                )
                + ". "
                + context.debugDescription

        default:

            return error.localizedDescription
        }
    }

    private func codingPathDescription(
        _ codingPath: [CodingKey]
    ) -> String {

        guard
            !codingPath.isEmpty
        else {
            return "<root>"
        }

        return codingPath
            .map {

                if let index =
                    $0.intValue
                {
                    return "[\(index)]"
                }

                return $0.stringValue
            }
            .joined(
                separator: "."
            )
    }

    // MARK: - Processing State

    private var canProcess: Bool {

        sourceFolderURL != nil
        && archiveFolderURL != nil
        && selectedFile != nil
    }

    // MARK: - DeviantArt Profile

    private func openDeviantArtProfile() {

        guard let url =
            watchersURL
        else {
            return
        }

        NSWorkspace.shared.open(
            url
        )
    }

    // MARK: - Source Folder Selection

    private func chooseSourceFolder() {

        let panel =
            NSOpenPanel()

        panel.title =
            "Choose Source Folder"

        panel.prompt =
            "Select"

        panel.canChooseFiles =
            false

        panel.canChooseDirectories =
            true

        panel.allowsMultipleSelection =
            false

        if let sourceFolderURL {
            panel.directoryURL =
                sourceFolderURL
        }

        guard
            panel.runModal() == .OK,
            let url = panel.url
        else {
            return
        }

        do {

            try bookmarkStore
                .saveSourceFolder(
                    url
                )

            sourceFolderURL =
                url

            errorMessage =
                nil

            refreshSourceFiles()

            startFolderWatcher()

        } catch {

            errorMessage =
                "Choosing source folder error: \(error.localizedDescription)"
        }
    }

    // MARK: - Archive Folder Selection

    private func chooseArchiveFolder() {

        let panel =
            NSOpenPanel()

        panel.title =
            "Choose Archive Folder"

        panel.prompt =
            "Select"

        panel.canChooseFiles =
            false

        panel.canChooseDirectories =
            true

        panel.allowsMultipleSelection =
            false

        if let archiveFolderURL {

            panel.directoryURL =
                archiveFolderURL
        }

        guard
            panel.runModal() == .OK,
            let url = panel.url
        else {
            return
        }

        do {

            try bookmarkStore
                .saveArchiveFolder(
                    url
                )

            archiveFolderURL =
                url

            errorMessage =
                nil

        } catch {

            errorMessage =
                "Choosing archive folder error: \(error.localizedDescription)"
        }
    }

    // MARK: - Source Files

    private func refreshSourceFiles() {

        guard let sourceFolderURL
        else {

            sourceFiles = []
            selectedFile = nil
            return
        }

        let accessGranted =
            sourceFolderURL
                .startAccessingSecurityScopedResource()

        defer {

            if accessGranted {

                sourceFolderURL
                    .stopAccessingSecurityScopedResource()
            }
        }

        do {

            let files =
                try FileManager.default
                    .contentsOfDirectory(
                        at:
                            sourceFolderURL,
                        includingPropertiesForKeys:
                            nil,
                        options:
                            [
                                .skipsHiddenFiles
                            ]
                    )

            sourceFiles =
                files
                    .filter {

                        !$0.hasDirectoryPath
                        && $0.pathExtension
                            .lowercased()
                        == "txt"
                    }
                    .sorted {

                        $0.lastPathComponent
                            .localizedCaseInsensitiveCompare(
                                $1.lastPathComponent
                            )
                        == .orderedAscending
                    }

            restorePreviousSelection()

            errorMessage =
                nil

        } catch {

            sourceFiles = []

            selectedFile =
                nil

            errorMessage =
                "Refreshing source files error: \(error.localizedDescription)"
        }
    }

    private func restorePreviousSelection() {

        guard
            let lastProcessedFileName
        else {

            selectedFile =
                nil

            return
        }

        selectedFile =
            sourceFiles.first {

                $0.lastPathComponent
                == lastProcessedFileName
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

            let report =
                try service.process(
                    sourceURL:
                        selectedFile,
                    archiveFolderURL:
                        archiveFolderURL
                )

            let processedFileName =
                selectedFile
                    .lastPathComponent

            lastProcessedFileName =
                processedFileName

            bookmarkStore
                .saveLastProcessedFileName(
                    processedFileName
                )

            appState.lastReport =
                report

            openWindow(
                id: "report"
            )

            errorMessage =
                nil

            loadCurrentSnapshot()

            refreshSourceFiles()

        } catch {

            errorMessage =
                "Processing selected file error: \(error.localizedDescription)"
        }
    }

    // MARK: - Restore

    private func restoreState() {

        sourceFolderURL =
            bookmarkStore
                .loadSourceFolder()

        archiveFolderURL =
            bookmarkStore
                .loadArchiveFolder()

        lastProcessedFileName =
            bookmarkStore
                .loadLastProcessedFileName()

        refreshSourceFiles()

        startFolderWatcher()

        loadLatestReport()

        loadCurrentSnapshot()

        loadFavourites()
    }

    // MARK: - Latest Report

    private func loadLatestReport() {

        guard
            let archiveFolderURL
        else {
            return
        }

        let accessGranted =
            archiveFolderURL
                .startAccessingSecurityScopedResource()

        defer {

            if accessGranted {

                archiveFolderURL
                    .stopAccessingSecurityScopedResource()
            }
        }

        do {

            guard
                let reportURL =
                    try archive
                        .latestReportURL(
                            in:
                                archiveFolderURL
                        )
            else {

                appState.lastReport =
                    nil

                return
            }

            appState.lastReport =
                try archive
                    .loadReport(
                        from:
                            reportURL
                    )

            errorMessage =
                nil

        } catch {

            errorMessage =
                "Load latest report error: \(error.localizedDescription)"
        }
    }

    // MARK: - Folder Watcher

    private func startFolderWatcher() {

        guard
            let sourceFolderURL
        else {

            folderWatcher.stop()
            return
        }

        folderWatcher.start(
            watching:
                sourceFolderURL
        ) {

            refreshSourceFiles()
        }
    }

    // MARK: - Current Snapshot

    private func loadCurrentSnapshot() {

        guard
            let archiveFolderURL
        else {

            appState.currentSnapshot =
                nil

            return
        }

        let accessGranted =
            archiveFolderURL
                .startAccessingSecurityScopedResource()

        defer {

            if accessGranted {

                archiveFolderURL
                    .stopAccessingSecurityScopedResource()
            }
        }

        do {

            guard
                let snapshotURL =
                    try archive
                        .latestSnapshotURL(
                            in:
                                archiveFolderURL
                        )
            else {

                appState.currentSnapshot =
                    nil

                return
            }

            appState.currentSnapshot =
                try archive
                    .loadSnapshot(
                        from:
                            snapshotURL
                    )

            errorMessage =
                nil

        } catch {

            errorMessage =
                "Load current snapshot error: \(error.localizedDescription)"
        }
    }

    // MARK: - Favourites

    private func loadFavourites() {

        guard
            let archiveFolderURL
        else {

            appState.favourites =
                []

            return
        }

        let accessGranted =
            archiveFolderURL
                .startAccessingSecurityScopedResource()

        defer {

            if accessGranted {

                archiveFolderURL
                    .stopAccessingSecurityScopedResource()
            }
        }

        do {

            appState.favourites =
                try favouritesStore
                    .load(
                        from:
                            archiveFolderURL
                    )

            errorMessage =
                nil

        } catch {

            errorMessage =
                "Loading favourites error: \(error.localizedDescription)"
        }
    }
}

private enum DeviantArtConnectionError:
    LocalizedError
{
    case invalidToken

    var errorDescription: String? {

        switch self {

        case .invalidToken:

            return
                "DeviantArt returned an invalid access token."
        }
    }
}

#Preview {
    ContentView()
}

