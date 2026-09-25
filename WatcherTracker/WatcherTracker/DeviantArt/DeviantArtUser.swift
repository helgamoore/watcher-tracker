//
//  DeviantArtUser.swift
//  WatcherTracker
//
//  Created by Helga Moore on 26/09/2026.
//

struct DeviantArtUser:
    Decodable
{
    let userID: String?
    let username: String
    let userIcon: String?
    let type: String?
    let isSubscribed: Bool?

    enum CodingKeys:
        String,
        CodingKey
    {
        case userID =
            "userid"

        case username

        case userIcon =
            "usericon"

        case type

        case isSubscribed =
            "is_subscribed"
    }
}
