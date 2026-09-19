//
//  Untitled.swift
//  WatcherTracker
//
//  Created by Helga Moore on 19/09/2026.
//

import Foundation

struct LocalAIGenerationRequest: Encodable {

    let prompt: String
    let negativePrompt: String
    let width: Int
    let height: Int
    let steps: Int
    let guidanceScale: Double
    let seed: UInt64?

    enum CodingKeys: String, CodingKey {
        case prompt

        case negativePrompt =
            "negative_prompt"

        case width
        case height
        case steps

        case guidanceScale =
            "guidance_scale"

        case seed
    }
}

struct LocalAIGenerationResponse: Decodable {

    let imageURL: String
    let seed: UInt64
    let generationSeconds: Double
    let width: Int
    let height: Int

    enum CodingKeys: String, CodingKey {
        case imageURL =
            "image_url"

        case seed

        case generationSeconds =
            "generation_seconds"

        case width
        case height
    }
}

struct LocalAIServerInfo: Decodable {

    let name: String
    let version: String
    let backend: String
    let models: [String]

    let modelLoaded: Bool
    let busy: Bool

    let state: String?

    let prompt: String?
    let negativePrompt: String?

    let width: Int?
    let height: Int?
    let steps: Int?

    let guidanceScale: Double?
    let seed: UInt64?

    let expectedFilename: String?

    let progressPercent: Double?
    let currentStep: Int?
    let totalSteps: Int?

    let logFile: String?

    enum CodingKeys: String, CodingKey {
        case name
        case version
        case backend
        case models

        case modelLoaded =
            "model_loaded"

        case busy
        case state
        case prompt

        case negativePrompt =
            "negative_prompt"

        case width
        case height
        case steps

        case guidanceScale =
            "guidance_scale"

        case seed

        case expectedFilename =
            "expected_filename"

        case progressPercent =
            "progress_percent"

        case currentStep =
            "current_step"

        case totalSteps =
            "total_steps"

        case logFile =
            "log_file"
    }
}
