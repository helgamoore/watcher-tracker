//
//  DeviantArtWatcher.swift
//  WatcherTracker
//
//  Created by Helga Moore on 26/09/2026.
//

struct DeviantArtWatcher: Decodable, Identifiable {

    let userID: String
    let username: String
    let userIcon: String?
    let type: String?

    var id: String {
        userID
    }

    enum CodingKeys: String, CodingKey {
        case userID = "userid"
        case username
        case userIcon = "usericon"
        case type
    }
}

struct DeviantArtWatchersPage:
    Decodable
{
    let results:
        [DeviantArtWatcherEntry]

    let hasMore: Bool

    let nextOffset: Int?

    enum CodingKeys:
        String,
        CodingKey
    {
        case results

        case hasMore =
            "has_more"

        case nextOffset =
            "next_offset"
    }
}

struct DeviantArtWatcherEntry:
    Decodable,
    Identifiable
{
    let user:
        DeviantArtUser

    let isWatching:
        Bool

    let lastVisit:
        String?

    let watch:
        DeviantArtWatchSettings

    var id: String {
        user.userID
        ?? user.username
    }

    enum CodingKeys:
        String,
        CodingKey
    {
        case user

        case isWatching =
            "is_watching"

        case lastVisit =
            "lastvisit"

        case watch
    }
}

struct DeviantArtWatchSettings:
    Decodable
{
    let friend: Bool
    let deviations: Bool
    let journals: Bool
    let forumThreads: Bool
    let critiques: Bool
    let scraps: Bool
    let activity: Bool
    let collections: Bool

    enum CodingKeys:
        String,
        CodingKey
    {
        case friend
        case deviations
        case journals

        case forumThreads =
            "forum_threads"

        case critiques
        case scraps
        case activity
        case collections
    }
}
