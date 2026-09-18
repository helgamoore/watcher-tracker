//
//  ServerProcessController.swift
//  AI Server Manager
//
//  Created by Helga Moore on 18/09/2026.
//

import Foundation

@MainActor
final class ServerProcessController {

    private var process: Process?

    private let serverFolder = URL(
        fileURLWithPath:
            "/Volumes/Samsung/Users/helga/projects/watcher-tracker/ai-server"
    )

    private var pythonURL: URL {
        serverFolder
            .appendingPathComponent(".venv")
            .appendingPathComponent("bin")
            .appendingPathComponent("python")
    }

    var isProcessRunning: Bool {
        process?.isRunning ?? false
    }

    func start() throws {
        guard !isProcessRunning else {
            return
        }

        let process = Process()

        process.executableURL = pythonURL

        process.arguments = [
            "-m",
            "uvicorn",
            "app.main:app",
            "--host",
            "127.0.0.1",
            "--port",
            "8765"
        ]

        process.currentDirectoryURL =
            serverFolder

        let logURL = serverFolder
            .appendingPathComponent(".runtime")
            .appendingPathComponent("server-manager.log")

        try FileManager.default.createDirectory(
            at: logURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        if !FileManager.default.fileExists(
            atPath: logURL.path
        ) {
            FileManager.default.createFile(
                atPath: logURL.path,
                contents: nil
            )
        }

        let logHandle = try FileHandle(
            forWritingTo: logURL
        )

        try logHandle.seekToEnd()

        process.standardOutput = logHandle
        process.standardError = logHandle

        process.terminationHandler = { process in
            print(
                "AI server terminated with status:",
                process.terminationStatus
            )
        }

        try process.run()

        self.process = process
    }

    func stop() {
        guard let process else {
            return
        }

        guard process.isRunning else {
            self.process = nil
            return
        }

        process.terminate()
    }
}
