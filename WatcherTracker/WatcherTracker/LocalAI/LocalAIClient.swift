//
//  LocalAIClient.swift
//  WatcherTracker
//
//  Created by Helga Moore on 19/09/2026.
//

import Foundation

struct LocalAIClient {

    let baseURL: URL

    init(
        baseURL: URL = URL(
            string:
                "http://127.0.0.1:8765"
        )!
    ) {
        self.baseURL = baseURL
    }

    // MARK: - Info

    func info() async throws
        -> LocalAIServerInfo
    {
        let url =
            baseURL
                .appendingPathComponent(
                    "info"
                )

        let (
            data,
            response
        ) =
            try await URLSession.shared
                .data(from: url)

        try validate(
            response: response,
            data: data
        )

        return try JSONDecoder()
            .decode(
                LocalAIServerInfo.self,
                from: data
            )
    }

    // MARK: - Health

    func health() async throws -> Bool {

        let url =
            baseURL
                .appendingPathComponent(
                    "health"
                )

        let (
            _,
            response
        ) =
            try await URLSession.shared
                .data(from: url)

        guard
            let httpResponse =
                response
                    as? HTTPURLResponse
        else {
            return false
        }

        return
            httpResponse.statusCode == 200
    }

    // MARK: - Generate

    func generate(
        _ generationRequest:
            LocalAIGenerationRequest
    ) async throws
        -> LocalAIGenerationResponse
    {
        let url =
            baseURL
                .appendingPathComponent(
                    "generate"
                )

        var request =
            URLRequest(url: url)

        request.httpMethod =
            "POST"

        request.setValue(
            "application/json",
            forHTTPHeaderField:
                "Content-Type"
        )

        request.timeoutInterval =
            600

        request.httpBody =
            try JSONEncoder()
                .encode(
                    generationRequest
                )

        let (
            data,
            response
        ) =
            try await URLSession.shared
                .data(for: request)

        try validate(
            response: response,
            data: data
        )

        return try JSONDecoder()
            .decode(
                LocalAIGenerationResponse.self,
                from: data
            )
    }

    // MARK: - Image URL

    func imageURL(
        for response:
            LocalAIGenerationResponse
    ) -> URL? {

        URL(
            string:
                response.imageURL,
            relativeTo:
                baseURL
        )?
        .absoluteURL
    }

    // MARK: - Response Validation

    private func validate(
        response: URLResponse,
        data: Data
    ) throws {

        guard
            let httpResponse =
                response
                    as? HTTPURLResponse
        else {
            throw LocalAIClientError
                .invalidResponse
        }

        guard
            200..<300 ~=
                httpResponse.statusCode
        else {

            let serverError =
                try? JSONDecoder()
                    .decode(
                        LocalAIErrorResponse.self,
                        from: data
                    )

            throw LocalAIClientError
                .serverError(
                    statusCode:
                        httpResponse
                            .statusCode,
                    message:
                        serverError?
                            .detail
                    ?? "Unknown server error."
                )
        }
    }
}

// MARK: - Error Response

private struct LocalAIErrorResponse:
    Decodable
{
    let detail: String
}

// MARK: - Errors

enum LocalAIClientError:
    LocalizedError
{
    case invalidResponse

    case serverError(
        statusCode: Int,
        message: String
    )

    var errorDescription: String? {

        switch self {

        case .invalidResponse:

            return
                "The local AI server returned an invalid response."

        case .serverError(
            let statusCode,
            let message
        ):

            return
                "Server error \(statusCode): \(message)"
        }
    }
}
