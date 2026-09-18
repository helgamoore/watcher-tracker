//
//  ServerAPIClient.swift
//  AI Server Manager
//
//  Created by Helga Moore on 18/09/2026.
//

import Foundation

struct ServerAPIClient {
    let baseURL: URL

    init(
        baseURL: URL = URL(
            string: "http://127.0.0.1:8765"
        )!
    ) {
        self.baseURL = baseURL
    }

    func health() async throws -> Bool {
        let url = baseURL.appendingPathComponent("health")

        let (_, response) = try await URLSession.shared.data(
            from: url
        )

        guard let httpResponse = response as? HTTPURLResponse else {
            return false
        }

        return httpResponse.statusCode == 200
    }

    func info() async throws -> ServerInfo {
        let url = baseURL.appendingPathComponent("info")

        let (data, response) = try await URLSession.shared.data(
            from: url
        )

        guard
            let httpResponse = response as? HTTPURLResponse,
            httpResponse.statusCode == 200
        else {
            throw ServerAPIError.invalidResponse
        }

        return try JSONDecoder().decode(
            ServerInfo.self,
            from: data
        )
    }

    var swaggerURL: URL {
        baseURL.appendingPathComponent("docs")
    }
    
    func generatedFiles() async throws
        -> [GeneratedImageFile]
    {
        let url =
            baseURL.appendingPathComponent(
                "generated-files"
            )

        let (data, response) =
            try await URLSession.shared.data(
                from: url
            )

        try validate(response)

        return try JSONDecoder()
            .decode(
                GeneratedFilesResponse.self,
                from: data
            )
            .files
    }

    func deleteGeneratedFile(
        _ file: GeneratedImageFile
    ) async throws {

        let url =
            baseURL
                .appendingPathComponent(
                    "generated-files"
                )
                .appendingPathComponent(
                    file.filename
                )

        var request = URLRequest(
            url: url
        )

        request.httpMethod = "DELETE"

        let (_, response) =
            try await URLSession.shared.data(
                for: request
            )

        try validate(response)
    }

    func deleteAllGeneratedFiles() async throws {
        let url =
            baseURL.appendingPathComponent(
                "generated-files"
            )

        var request = URLRequest(
            url: url
        )

        request.httpMethod = "DELETE"

        let (_, response) =
            try await URLSession.shared.data(
                for: request
            )

        try validate(response)
    }

    func imageURL(
        for file: GeneratedImageFile
    ) -> URL? {
        URL(
            string: file.imageURL,
            relativeTo: baseURL
        )?.absoluteURL
    }

    private func validate(
        _ response: URLResponse
    ) throws {
        guard
            let httpResponse =
                response as? HTTPURLResponse,
            200..<300 ~= httpResponse.statusCode
        else {
            throw ServerAPIError.invalidResponse
        }
    }
}

enum ServerAPIError: Error {
    case invalidResponse
}
