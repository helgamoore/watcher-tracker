import SwiftUI
import AppKit

struct ContentView: View {

    @EnvironmentObject
    private var appState: AppState

    @Environment(\.openWindow)
    private var openWindow

    @State
    private var archiveFolderURL: URL?

    @State
    private var errorMessage: String?

    @State
    private var isConnectingDeviantArt = false

    @State
    private var deviantArtStatusMessage: String?

    @State
    private var deviantArtErrorMessage: String?

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
                    "Fetch watcher data directly from DeviantArt, review changes, and manage tracked artists."
                )
                .foregroundStyle(
                    .secondary
                )
            }

            Divider()

            archiveFolderSection

            watcherSourceSection

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

    // MARK: - Watcher Source

    private var watcherSourceSection: some View {

        HStack {

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text("Watcher source")
                    .font(.headline)

                Text(
                    deviantArtUsername.isEmpty
                    ? "DeviantArt API · not connected yet"
                    : "DeviantArt API · \(deviantArtUsername)"
                )
                .foregroundStyle(
                    .secondary
                )
            }

            Spacer()

            if appState.currentSnapshot != nil {

                Text(
                    "\(appState.currentSnapshot?.count ?? 0) watchers"
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
            alignment: .leading,
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

                Spacer()
            }

            HStack {

                Button {

                    openWindow(
                        id: "favourites"
                    )

                } label: {

                    Label(
                        "Favourites",
                        systemImage:
                            "star.fill"
                    )
                }

                Button {

                    openWindow(
                        id:
                            "report-history"
                    )

                } label: {

                    Label(
                        "History",
                        systemImage:
                            "calendar"
                    )
                }

                Spacer()

                Button {

                    updateWatchersFromDeviantArt()

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
                                "Updating…"
                            )
                        }

                    } else {

                        Text(
                            "Update Watchers"
                        )
                    }
                }
                .buttonStyle(
                    .borderedProminent
                )
                .keyboardShortcut(
                    .defaultAction
                )
                .disabled(
                    isConnectingDeviantArt
                    || archiveFolderURL == nil
                )
            }
        }
    }
    // MARK: - DeviantArt Connection

    private func updateWatchersFromDeviantArt() {

        guard
            !isConnectingDeviantArt
        else {
            return
        }

        guard
            archiveFolderURL != nil
        else {

            deviantArtErrorMessage =
                "Choose an archive folder before updating watchers."

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

                deviantArtStatusMessage =
                    "Authenticated. Validating token…"

                let client =
                    DeviantArtClient(
                        accessToken:
                            token.accessToken
                    )

                let valid =
                    try await client
                        .validateToken()

                guard valid
                else {

                    throw DeviantArtConnectionError
                        .invalidToken
                }

                let user =
                    try await client
                        .whoAmI()

                deviantArtUsername =
                    user.username

                deviantArtStatusMessage =
                    "Connected as \(user.username). Loading watchers…"

                let watchers =
                    try await client
                        .allWatchers(
                            username:
                                user.username
                        )

                deviantArtStatusMessage =
                    "Loaded \(watchers.count) watchers. Updating archive…"

                let report =
                    try processDeviantArtWatchers(
                        watchers
                    )

                deviantArtStatusMessage =
                    "Updated \(report.total) watchers: "
                    + "\(report.added.count) added, "
                    + "\(report.removed.count) removed."

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

    private func processDeviantArtWatchers(
        _ watchers:
            [DeviantArtWatcherEntry]
    ) throws -> WatcherReport {

        guard
            let archiveFolderURL
        else {

            throw DeviantArtConnectionError
                .archiveFolderRequired
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

        let now =
            Date()

        let usernames =
            Array(
                Set(
                    watchers.map {
                        $0.user.username
                    }
                )
            )
            .sorted {
                $0.localizedCaseInsensitiveCompare(
                    $1
                ) == .orderedAscending
            }

        let snapshot =
            WatcherSnapshot(
                date:
                    now,
                watchers:
                    usernames
            )

        let previousSnapshot:
            WatcherSnapshot?

        if let previousURL =
            try archive
                .latestSnapshotURL(
                    in:
                        archiveFolderURL,
                    before:
                        now
                )
        {
            previousSnapshot =
                try archive
                    .loadSnapshot(
                        from:
                            previousURL
                    )

        } else {

            previousSnapshot =
                nil
        }

        let currentSet =
            Set(
                snapshot.watchers
            )

        let previousSet =
            Set(
                previousSnapshot?
                    .watchers
                ?? []
            )

        let added =
            currentSet
                .subtracting(
                    previousSet
                )
                .sorted {
                    $0.localizedCaseInsensitiveCompare(
                        $1
                    ) == .orderedAscending
                }

        let removed =
            previousSet
                .subtracting(
                    currentSet
                )
                .sorted {
                    $0.localizedCaseInsensitiveCompare(
                        $1
                    ) == .orderedAscending
                }

        let report =
            WatcherReport(
                date:
                    now,
                added:
                    added,
                removed:
                    removed,
                total:
                    snapshot.count
            )

        _ =
            try archive.save(
                snapshot,
                to:
                    archiveFolderURL
            )

        _ =
            try archive.save(
                report,
                to:
                    archiveFolderURL
            )

        appState.currentSnapshot =
            snapshot

        appState.lastReport =
            report

        openWindow(
            id: "report"
        )

        errorMessage =
            nil

        return report
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

            loadLatestReport()
            loadCurrentSnapshot()
            loadFavourites()

            errorMessage =
                nil

        } catch {

            errorMessage =
                "Choosing archive folder error: \(error.localizedDescription)"
        }
    }

    // MARK: - Restore

    private func restoreState() {

        archiveFolderURL =
            bookmarkStore
                .loadArchiveFolder()

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
    case archiveFolderRequired

    var errorDescription: String? {

        switch self {

        case .invalidToken:

            return
                "DeviantArt returned an invalid access token."

        case .archiveFolderRequired:

            return
                "Choose an archive folder before updating watchers."
        }
    }
}

#Preview {
    ContentView()
}


