//
//  DeviantArtClient.swift
//  WatcherTracker
//
//  Created by Helga Moore on 26/09/2026.
//

import Foundation

struct DeviantArtClient {

    private let accessToken: String

    init(
        accessToken: String
    ) {
        self.accessToken =
            accessToken
    }

    func validateToken() async throws
        -> Bool
    {
        let url =
            URL(
                string:
                    "https://www.deviantart.com/api/v1/oauth2/placebo"
            )!

        var request =
            URLRequest(
                url: url
            )

        request.setValue(
            "Bearer \(accessToken)",
            forHTTPHeaderField:
                "Authorization"
        )

        request.setValue(
            "WatcherTracker/1.0",
            forHTTPHeaderField:
                "User-Agent"
        )

        request.setValue(
            "gzip, deflate",
            forHTTPHeaderField:
                "Accept-Encoding"
        )

        let (
            data,
            response
        ) =
            try await
                URLSession.shared
                    .data(
                        for:
                            request
                    )

        guard
            let httpResponse =
                response
                    as? HTTPURLResponse
        else {
            throw DeviantArtClientError
                .invalidResponse
        }

        guard
            200..<300 ~=
                httpResponse.statusCode
        else {

            throw DeviantArtClientError
                .httpError(
                    httpResponse.statusCode
                )
        }

        let result =
            try JSONDecoder()
                .decode(
                    PlaceboResponse.self,
                    from:
                        data
                )

        return
            result.status ==
            "success"
    }
    
    func whoAmI() async throws
        -> DeviantArtUser
    {
        let url =
            URL(
                string:
                    "https://www.deviantart.com/api/v1/oauth2/user/whoami"
            )!

        var request =
            URLRequest(
                url: url
            )

        request.setValue(
            "Bearer \(accessToken)",
            forHTTPHeaderField:
                "Authorization"
        )

        request.setValue(
            "WatcherTracker/1.0",
            forHTTPHeaderField:
                "User-Agent"
        )

        request.setValue(
            "gzip, deflate",
            forHTTPHeaderField:
                "Accept-Encoding"
        )

        let (
            data,
            response
        ) =
            try await
                URLSession.shared
                    .data(
                        for:
                            request
                    )

        guard
            let httpResponse =
                response
                    as? HTTPURLResponse
        else {
            throw DeviantArtClientError
                .invalidResponse
        }

        guard
            200..<300 ~=
                httpResponse.statusCode
        else {
            throw DeviantArtClientError
                .httpError(
                    httpResponse.statusCode
                )
        }

        return try JSONDecoder()
            .decode(
                DeviantArtUser.self,
                from:
                    data
            )
    }
    
    func watchers(
        username: String,
        offset: Int = 0,
        limit: Int = 50
    ) async throws -> DeviantArtWatchersPage {

        var components =
            URLComponents(
                string:
                    "https://www.deviantart.com/api/v1/oauth2/user/watchers/\(username)"
            )!

        components.queryItems = [
            URLQueryItem(
                name: "offset",
                value: "\(offset)"
            ),
            URLQueryItem(
                name: "limit",
                value: "\(limit)"
            )
        ]

        guard
            let url =
                components.url
        else {
            throw DeviantArtClientError
                .invalidResponse
        }

        var request =
            URLRequest(
                url: url
            )

        request.setValue(
            "Bearer \(accessToken)",
            forHTTPHeaderField:
                "Authorization"
        )

        request.setValue(
            "WatcherTracker/1.0",
            forHTTPHeaderField:
                "User-Agent"
        )

        request.setValue(
            "gzip, deflate",
            forHTTPHeaderField:
                "Accept-Encoding"
        )

        let (
            data,
            response
        ) =
            try await
                URLSession.shared
                    .data(
                        for: request
                    )

        guard
            let httpResponse =
                response
                    as? HTTPURLResponse
        else {
            throw DeviantArtClientError
                .invalidResponse
        }

        guard
            200..<300 ~=
                httpResponse.statusCode
        else {
            throw DeviantArtClientError
                .httpError(
                    httpResponse.statusCode
                )
        }

        if let json =
            String(
                data: data,
                encoding: .utf8
            )
        {
            print(
                "WATCHERS RAW JSON:"
            )

            print(json)
        }

        return try JSONDecoder()
            .decode(
                DeviantArtWatchersPage.self,
                from: data
            )
    }
    
    func allWatchers(
        username: String
    ) async throws
        -> [DeviantArtWatcherEntry]
    {
        var allResults:
            [DeviantArtWatcherEntry] = []

        var offset = 0

        while true {

            let page =
                try await watchers(
                    username:
                        username,
                    offset:
                        offset,
                    limit:
                        50
                )

            allResults.append(
                contentsOf:
                    page.results
            )

            print(
                "Loaded \(allResults.count) watchers..."
            )

            guard
                page.hasMore,
                let nextOffset =
                    page.nextOffset
            else {
                break
            }

            guard
                nextOffset > offset
            else {
                throw DeviantArtClientError
                    .invalidPagination
            }

            offset =
                nextOffset
        }

        return allResults
    }
}

private struct PlaceboResponse:
    Decodable
{
    let status: String
}

enum DeviantArtClientError:
    LocalizedError
{
    case invalidResponse

    case invalidPagination
    
    case httpError(
        Int
    )

    var errorDescription:
        String?
    {
        switch self {

        case .invalidResponse:

            return
                "DeviantArt returned an invalid response."

        case .invalidPagination:

            return
                "DeviantArt returned an invalid pagination offset."
            
        case .httpError(
            let statusCode
        ):

            return
                "DeviantArt returned HTTP \(statusCode)."
        }
    }
}
