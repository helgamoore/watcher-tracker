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

    private let api = ServerAPIClient()

    private let processController =
        ServerProcessController()

    private var monitoringTask: Task<Void, Never>?

    func startMonitoring() {
        guard monitoringTask == nil else {
            return
        }

        monitoringTask = Task {
            while !Task.isCancelled {

                await refreshStatus()

                try? await Task.sleep(
                    for: .seconds(1)
                )
            }
        }
    }

    func stopMonitoring() {
        monitoringTask?.cancel()
        monitoringTask = nil
    }

    func refreshStatus() async {
        do {
            let serverInfo = try await api.info()

            info = serverInfo
            errorMessage = nil

            state = serverInfo.busy
                ? .busy
                : .idle

        } catch {

            info = nil

            if processController.isProcessRunning {
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

        do {
            try processController.start()

            Task {
                // Give Uvicorn a moment to start.
                try? await Task.sleep(
                    for: .seconds(1)
                )

                await refreshStatus()
            }

        } catch {
            state = .unavailable
            errorMessage =
                "Starting server failed: \(error.localizedDescription)"
        }
    }

    func stopServer() {
        processController.stop()

        Task {
            try? await Task.sleep(
                for: .milliseconds(500)
            )

            await refreshStatus()
        }
    }

    func openSwagger() {
        NSWorkspace.shared.open(
            api.swaggerURL
        )
    }
}
