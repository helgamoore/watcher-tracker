//
//  GeneratedImageFile.swift
//  AI Server Manager
//
//  Created by Helga Moore on 18/09/2026.
//

import Foundation

struct GeneratedImageFile:
    Codable,
    Identifiable,
    Hashable
{
    let filename: String
    let imageURL: String
    let sizeBytes: Int64
    let modifiedAt: String

    var id: String {
        filename
    }

    enum CodingKeys:
        String,
        CodingKey
    {
        case filename
        case imageURL = "image_url"
        case sizeBytes = "size_bytes"
        case modifiedAt = "modified_at"
    }
}

struct GeneratedFilesResponse: Codable {
    let count: Int
    let files: [GeneratedImageFile]
}
