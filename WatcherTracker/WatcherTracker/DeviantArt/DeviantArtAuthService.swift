//
//  DeviantArtAuthService.swift
//  WatcherTracker
//
//  Created by Helga Moore on 26/09/2026.//
//


import Foundation
import AuthenticationServices
import CryptoKit

@MainActor
final class DeviantArtAuthService:
    NSObject,
    ASWebAuthenticationPresentationContextProviding
{
    private let clientID: String

    private let redirectURI =
        "watchertracker://oauth/deviantart"

    private let scopes = [
        "basic",
        "browse"
    ]

    private var authenticationSession:
        ASWebAuthenticationSession?

    init(
        clientID: String
    ) {
        self.clientID =
            clientID
    }

    func authorize() async throws
        -> DeviantArtTokenResponse
    {
        let verifier =
            generateCodeVerifier()

        let challenge =
            codeChallenge(
                for: verifier
            )

        let state =
            UUID().uuidString

        guard
            let authorizationURL =
                makeAuthorizationURL(
                    state: state,
                    codeChallenge:
                        challenge
                )
        else {
            throw DeviantArtAuthError
                .invalidAuthorizationURL
        }

        let callbackURL =
            try await authenticate(
                url:
                    authorizationURL
            )

        guard
            let components =
                URLComponents(
                    url:
                        callbackURL,
                    resolvingAgainstBaseURL:
                        false
                )
        else {
            throw DeviantArtAuthError
                .invalidCallback
        }

        let queryItems =
            components.queryItems
            ?? []

        if let error =
            queryItems.first(
                where: {
                    $0.name == "error"
                }
            )?
            .value
        {
            let description =
                queryItems.first(
                    where: {
                        $0.name ==
                            "error_description"
                    }
                )?
                .value

            throw DeviantArtAuthError
                .authorizationFailed(
                    description
                    ?? error
                )
        }

        let returnedState =
            queryItems.first(
                where: {
                    $0.name == "state"
                }
            )?
            .value

        guard
            returnedState == state
        else {
            throw DeviantArtAuthError
                .invalidState
        }

        guard
            let code =
                queryItems.first(
                    where: {
                        $0.name == "code"
                    }
                )?
                .value
        else {
            throw DeviantArtAuthError
                .missingAuthorizationCode
        }

        return try await exchangeCode(
            code,
            verifier:
                verifier
        )
    }

    // MARK: - Authorization URL

    private func makeAuthorizationURL(
        state: String,
        codeChallenge: String
    ) -> URL? {

        var components =
            URLComponents(
                string:
                    "https://www.deviantart.com/oauth2/authorize"
            )

        components?
            .queryItems = [

                URLQueryItem(
                    name:
                        "response_type",
                    value:
                        "code"
                ),

                URLQueryItem(
                    name:
                        "client_id",
                    value:
                        clientID
                ),

                URLQueryItem(
                    name:
                        "redirect_uri",
                    value:
                        redirectURI
                ),

                URLQueryItem(
                    name:
                        "scope",
                    value:
                        scopes.joined(
                            separator:
                                " "
                        )
                ),

                URLQueryItem(
                    name:
                        "state",
                    value:
                        state
                ),

                URLQueryItem(
                    name:
                        "code_challenge",
                    value:
                        codeChallenge
                ),

                URLQueryItem(
                    name:
                        "code_challenge_method",
                    value:
                        "S256"
                )
            ]

        return components?.url
    }

    // MARK: - Authentication Session

    private func authenticate(
        url: URL
    ) async throws -> URL {

        try await withCheckedThrowingContinuation {
            continuation in

            let session =
                ASWebAuthenticationSession(
                    url: url,
                    callbackURLScheme:
                        "watchertracker"
                ) {
                    callbackURL,
                    error in

                    if let error {

                        continuation
                            .resume(
                                throwing:
                                    error
                            )

                        return
                    }

                    guard
                        let callbackURL
                    else {

                        continuation
                            .resume(
                                throwing:
                                    DeviantArtAuthError
                                        .invalidCallback
                            )

                        return
                    }

                    continuation
                        .resume(
                            returning:
                                callbackURL
                        )
                }

            session.presentationContextProvider =
                self

            // We want the normal browser session,
            // not an isolated one.
            session.prefersEphemeralWebBrowserSession =
                false

            authenticationSession =
                session

            session.start()
        }
    }

    // MARK: - Token Exchange

    private func exchangeCode(
        _ code: String,
        verifier: String
    ) async throws
        -> DeviantArtTokenResponse
    {
        let url =
            URL(
                string:
                    "https://www.deviantart.com/oauth2/token"
            )!

        var request =
            URLRequest(
                url: url
            )

        request.httpMethod =
            "POST"

        request.setValue(
            "application/x-www-form-urlencoded",
            forHTTPHeaderField:
                "Content-Type"
        )

        let parameters = [
            "grant_type":
                "authorization_code",

            "client_id":
                clientID,

            "redirect_uri":
                redirectURI,

            "code":
                code,

            "code_verifier":
                verifier
        ]

        request.httpBody =
            formEncoded(
                parameters
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

            throw DeviantArtAuthError
                .invalidTokenResponse
        }

        guard
            200..<300 ~=
                httpResponse
                    .statusCode
        else {

            if let apiError =
                try?
                    JSONDecoder()
                        .decode(
                            DeviantArtOAuthError
                                .self,
                            from:
                                data
                        )
            {
                throw DeviantArtAuthError
                    .tokenExchangeFailed(
                        apiError
                            .errorDescription
                        ?? apiError.error
                    )
            }

            throw DeviantArtAuthError
                .tokenExchangeFailed(
                    "HTTP \(httpResponse.statusCode)"
                )
        }

        return try JSONDecoder()
            .decode(
                DeviantArtTokenResponse.self,
                from:
                    data
            )
    }

    // MARK: - PKCE

    private func generateCodeVerifier()
        -> String
    {
        var bytes =
            [UInt8](
                repeating: 0,
                count: 32
            )

        _ =
            SecRandomCopyBytes(
                kSecRandomDefault,
                bytes.count,
                &bytes
            )

        return Data(bytes)
            .base64URLEncodedString()
    }

    private func codeChallenge(
        for verifier: String
    ) -> String {

        let data =
            Data(
                verifier.utf8
            )

        let digest =
            SHA256.hash(
                data: data
            )

        return Data(digest)
            .base64URLEncodedString()
    }

    // MARK: - Form Encoding

    private func formEncoded(
        _ parameters:
            [String: String]
    ) -> Data {

        let string =
            parameters
                .map {
                    key,
                    value in

                    "\(urlEncode(key))=\(urlEncode(value))"
                }
                .joined(
                    separator: "&"
                )

        return Data(
            string.utf8
        )
    }

    private func urlEncode(
        _ value: String
    ) -> String {

        var allowed =
            CharacterSet
                .urlQueryAllowed

        allowed.remove(
            charactersIn:
                "&+=?"
        )

        return value
            .addingPercentEncoding(
                withAllowedCharacters:
                    allowed
            )
        ?? value
    }

    // MARK: - Presentation Context

    func presentationAnchor(
        for session:
            ASWebAuthenticationSession
    ) -> ASPresentationAnchor {

        NSApplication.shared
            .keyWindow
        ?? ASPresentationAnchor()
    }
}

// MARK: - Models

struct DeviantArtTokenResponse:
    Decodable
{
    let accessToken: String
    let refreshToken: String?
    let tokenType: String
    let expiresIn: Int
    let scope: String?

    enum CodingKeys:
        String,
        CodingKey
    {
        case accessToken =
            "access_token"

        case refreshToken =
            "refresh_token"

        case tokenType =
            "token_type"

        case expiresIn =
            "expires_in"

        case scope
    }
}

private struct DeviantArtOAuthError:
    Decodable
{
    let error: String

    let errorDescription:
        String?

    enum CodingKeys:
        String,
        CodingKey
    {
        case error

        case errorDescription =
            "error_description"
    }
}

// MARK: - Errors

enum DeviantArtAuthError:
    LocalizedError
{
    case invalidAuthorizationURL
    case invalidCallback
    case invalidState
    case missingAuthorizationCode
    case invalidTokenResponse

    case authorizationFailed(
        String
    )

    case tokenExchangeFailed(
        String
    )

    var errorDescription:
        String?
    {
        switch self {

        case .invalidAuthorizationURL:

            return
                "Unable to create the DeviantArt authorization URL."

        case .invalidCallback:

            return
                "DeviantArt returned an invalid authorization callback."

        case .invalidState:

            return
                "The DeviantArt authorization state did not match."

        case .missingAuthorizationCode:

            return
                "DeviantArt did not return an authorization code."

        case .invalidTokenResponse:

            return
                "DeviantArt returned an invalid token response."

        case .authorizationFailed(
            let message
        ):

            return
                "DeviantArt authorization failed: \(message)"

        case .tokenExchangeFailed(
            let message
        ):

            return
                "DeviantArt token exchange failed: \(message)"
        }
    }
}

// MARK: - Base64 URL

private extension Data {

    func base64URLEncodedString()
        -> String
    {
        base64EncodedString()
            .replacingOccurrences(
                of: "+",
                with: "-"
            )
            .replacingOccurrences(
                of: "/",
                with: "_"
            )
            .replacingOccurrences(
                of: "=",
                with: ""
            )
    }
}
