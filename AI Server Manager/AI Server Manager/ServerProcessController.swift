//
//  ServerProcessController.swift
//  AI Server Manager
//
//  Created by Helga Moore on 18/09/2026.
//

import Foundation

final class ServerProcessController {

    private let serverFolder = URL(
        fileURLWithPath:
            "/Volumes/Samsung/Users/helga/projects/watcher-tracker/ai-server"
    )

    private var scriptsFolder: URL {
        serverFolder
            .appendingPathComponent("scripts")
    }

    private var startScript: URL {
        scriptsFolder
            .appendingPathComponent("start-server.sh")
    }

    private var stopScript: URL {
        scriptsFolder
            .appendingPathComponent("stop-server.sh")
    }

    private var statusScript: URL {
        scriptsFolder
            .appendingPathComponent("status-server.sh")
    }

    func start() async throws {
        try await runScript(startScript)
    }

    func stop() async throws {
        try await runScript(stopScript)
    }

    func isProcessRunning() async -> Bool {
        do {
            try await runScript(statusScript)
            return true
        } catch {
            return false
        }
    }

    private func runScript(
        _ scriptURL: URL
    ) async throws {

        try await Task.detached {

            let process = Process()

            process.executableURL = URL(
                fileURLWithPath: "/bin/bash"
            )

            process.arguments = [
                scriptURL.path
            ]

            process.currentDirectoryURL =
                self.serverFolder

            let outputPipe = Pipe()
            let errorPipe = Pipe()

            process.standardOutput = outputPipe
            process.standardError = errorPipe

            try process.run()
            process.waitUntilExit()

            let outputData =
                outputPipe.fileHandleForReading
                    .readDataToEndOfFile()

            let errorData =
                errorPipe.fileHandleForReading
                    .readDataToEndOfFile()

            let output =
                String(
                    data: outputData,
                    encoding: .utf8
                ) ?? ""

            let error =
                String(
                    data: errorData,
                    encoding: .utf8
                ) ?? ""

            if !output.isEmpty {
                print(output)
            }

            guard process.terminationStatus == 0 else {
                throw ServerProcessError.scriptFailed(
                    error.isEmpty
                        ? output
                        : error
                )
            }
        }.value
    }
}

enum ServerProcessError:
    LocalizedError
{
    case scriptFailed(String)

    var errorDescription: String? {
        switch self {
        case .scriptFailed(let message):
            return message.isEmpty
                ? "Server script failed."
                : message
        }
    }
}
