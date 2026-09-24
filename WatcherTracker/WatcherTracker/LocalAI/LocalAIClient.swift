//
//  LocalAIClient.swift
//  WatcherTracker
//

import Foundation

struct LocalAIClient {

    let baseURL: URL

    private let session:
        URLSession

    init(
        baseURL: URL = URL(
            string:
                "http://mini256.local:8765"
        )!
    ) {
        self.baseURL =
            baseURL

        let configuration =
            URLSessionConfiguration
                .default

        configuration
            .waitsForConnectivity =
            true

        self.session =
            URLSession(
                configuration:
                    configuration
            )
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
            try await session
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
            try await session
                .data(from: url)

        guard
            let httpResponse =
                response
                    as? HTTPURLResponse
        else {
            return false
        }

        return
            httpResponse.statusCode ==
            200
    }

    // MARK: - Start Generation Job

    func startGeneration(
        _ generationRequest:
            LocalAIGenerationRequest,
        jobID: String
    ) async throws
        -> LocalAIJobStartResponse
    {
        let url =
            baseURL
                .appendingPathComponent(
                    "jobs"
                )
                .appendingPathComponent(
                    jobID
                )

        var request =
            URLRequest(url: url)

        request.httpMethod =
            "PUT"

        request.setValue(
            "application/json",
            forHTTPHeaderField:
                "Content-Type"
        )

        request.timeoutInterval =
            30

        request.httpBody =
            try JSONEncoder()
                .encode(
                    generationRequest
                )

        let (
            data,
            response
        ) =
            try await session
                .data(for: request)

        try validate(
            response: response,
            data: data
        )

        return try JSONDecoder()
            .decode(
                LocalAIJobStartResponse.self,
                from: data
            )
    }

    // MARK: - Generation Job

    func job(
        _ jobID: String
    ) async throws
        -> LocalAIGenerationJob
    {
        let url =
            baseURL
                .appendingPathComponent(
                    "jobs"
                )
                .appendingPathComponent(
                    jobID
                )

        let (
            data,
            response
        ) =
            try await session
                .data(from: url)

        try validate(
            response: response,
            data: data
        )

        return try JSONDecoder()
            .decode(
                LocalAIGenerationJob.self,
                from: data
            )
    }

    // MARK: - Convenience Generate
    //
    // Useful for clients that stay in the foreground,
    // including the current macOS client. Mobile clients
    // should keep the job ID themselves so they can resume
    // after suspension.

    func generate(
        _ generationRequest:
            LocalAIGenerationRequest
    ) async throws
        -> LocalAIGenerationResponse
    {
        let jobID =
            UUID().uuidString

        // The job ID is created by the client before the
        // request is sent. PUT /jobs/{id} is idempotent,
        // so if the connection disappears after the server
        // accepted the job, retrying the same request will
        // not start a second generation.

        while true {

            try Task
                .checkCancellation()

            do {

                _ =
                    try await startGeneration(
                        generationRequest,
                        jobID:
                            jobID
                    )

                break

            } catch is URLError {

                try await Task.sleep(
                    for:
                        .seconds(1)
                )

                continue
            }
        }

        // Poll the server-side job. Temporary connection
        // failures are not generation failures. This is
        // important on iOS/iPadOS, where the app may be
        // suspended while the Mac continues generating.

        while true {

            try Task
                .checkCancellation()

            do {

                let generationJob =
                    try await job(
                        jobID
                    )

                switch generationJob.status {

                case .running:

                    try await Task.sleep(
                        for:
                            .seconds(1)
                    )

                case .completed:

                    guard
                        let result =
                            generationJob.result
                    else {
                        throw LocalAIClientError
                            .invalidResponse
                    }

                    return result

                case .failed:

                    throw LocalAIClientError
                        .jobFailed(
                            generationJob.error
                            ?? "Generation failed."
                        )
                }

            } catch is URLError {

                try await Task.sleep(
                    for:
                        .seconds(1)
                )
            }
        }
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

    case jobFailed(
        String
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

        case .jobFailed(
            let message
        ):

            return
                message
        }
    }

    var statusCode: Int? {

        switch self {

        case .serverError(
            let statusCode,
            _
        ):

            return statusCode

        default:

            return nil
        }
    }
}
