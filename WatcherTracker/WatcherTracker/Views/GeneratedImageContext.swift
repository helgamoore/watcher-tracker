//
//  GeneratedImageContext.swift
//  WatcherTracker
//
//  Created by Helga Moore on 19/09/2026.
//

import Foundation

struct GeneratedImageParameter:
    Codable,
    Hashable
{
    let name: String
    let value: String
}

struct GeneratedImageContext:
    Codable,
    Hashable
{
    let imageURL: URL
    let provider: String
    let prompt: String
    let parameters: [GeneratedImageParameter]
}
