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
}

enum ServerAPIError: Error {
    case invalidResponse
}
