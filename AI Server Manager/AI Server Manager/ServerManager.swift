//
//  ServerManager.swift
//  AI Server Manager
//
//  Created by Helga Moore on 18/09/2026.
//

import Foundation
import AppKit
import Combine

@MainActor
final class ServerManager: ObservableObject {

    @Published private(set)
    var state: ServerState = .stopped

    @Published private(set)
    var info: ServerInfo?

    @Published private(set)
    var errorMessage: String?

    @Published private(set)
    var generatedFiles:
        [GeneratedImageFile] = []
    
    @Published private(set)
    var testGenerationRunning = false
    
    private let api = ServerAPIClient()

    private let processController =
        ServerProcessController()

    private var monitoringTask: Task<Void, Never>?

    private var isPanelVisible = false
    
    func startMonitoring() {
        guard monitoringTask == nil else {
            return
        }

        createMonitoringTask()
    }

    func stopMonitoring() {
        monitoringTask?.cancel()
        monitoringTask = nil
    }

    func setPanelVisible(_ visible: Bool) {
        guard isPanelVisible != visible else {
            return
        }

        isPanelVisible = visible

        // Restart the polling loop so the new interval
        // takes effect immediately.
        monitoringTask?.cancel()
        monitoringTask = nil

        createMonitoringTask()
    }

    private func createMonitoringTask() {
        monitoringTask = Task { [weak self] in
            guard let self else {
                return
            }

            while !Task.isCancelled {
                await refreshStatus()

                let interval: Duration =
                    isPanelVisible
                    ? .seconds(1)
                    : .seconds(10)

                do {
                    try await Task.sleep(
                        for: interval
                    )
                } catch {
                    return
                }
            }
        }
    }

    func refreshStatus() async {
        do {
            let serverInfo =
                try await api.info()

            info = serverInfo
            errorMessage = nil

            state = serverInfo.busy
                ? .busy
                : .idle

        } catch {

            info = nil

            if state == .starting {
                return
            }

            let processRunning =
                await processController
                    .isProcessRunning()

            if processRunning {
                state = .unavailable

                errorMessage =
                    "Server process is running but the API is unavailable."
            } else {
                state = .stopped
                errorMessage = nil
            }
        }
    }

    func startServer() {
        guard state == .stopped ||
              state == .unavailable
        else {
            return
        }

        state = .starting
        errorMessage = nil

        Task {
            do {
                try await processController.start()

                await waitForServerStartup()

            } catch {
                state = .unavailable
                errorMessage =
                    "Starting server failed: \(error.localizedDescription)"
            }
        }
    }

    private func waitForServerStartup() async {

        for _ in 0..<30 {

            do {
                let serverInfo =
                    try await api.info()

                info = serverInfo
                errorMessage = nil

                state = serverInfo.busy
                    ? .busy
                    : .idle

                return

            } catch {
                // Uvicorn is still starting.
            }

            try? await Task.sleep(
                for: .milliseconds(500)
            )
        }

        state = .unavailable

        errorMessage =
            "Server process started, but the API did not become available."
    }
    
    func stopServer() {
        Task {
            do {
                try await processController.stop()

                info = nil
                state = .stopped
                errorMessage = nil

            } catch {
                errorMessage =
                    "Stopping server failed: \(error.localizedDescription)"

                await refreshStatus()
            }
        }
    }

    func openSwagger() {
        NSWorkspace.shared.open(
            api.swaggerURL
        )
    }
    
    func refreshGeneratedFiles() async {
        do {
            generatedFiles =
                try await api.generatedFiles()

            errorMessage = nil

        } catch {
            errorMessage =
                "Loading generated images failed: \(error.localizedDescription)"
        }
    }

    func deleteGeneratedFile(
        _ file: GeneratedImageFile
    ) async {
        do {
            try await api.deleteGeneratedFile(
                file
            )

            await refreshGeneratedFiles()

        } catch {
            errorMessage =
                "Deleting image failed: \(error.localizedDescription)"
        }
    }

    func deleteAllGeneratedFiles() async {
        do {
            try await api
                .deleteAllGeneratedFiles()

            generatedFiles = []

        } catch {
            errorMessage =
                "Deleting images failed: \(error.localizedDescription)"
        }
    }

    func imageURL(
        for file: GeneratedImageFile
    ) -> URL? {
        api.imageURL(for: file)
    }
    
    func generateTestImage(
        prompt: String
    ) async {

        guard !prompt
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .isEmpty
        else {
            return
        }

        testGenerationRunning = true

        defer {
            testGenerationRunning = false
        }

        do {
            try await api.generateTestImage(
                prompt: prompt
            )

            await refreshStatus()
            await refreshGeneratedFiles()

        } catch {
            errorMessage =
                "Test generation failed: \(error.localizedDescription)"
        }
    }
}
