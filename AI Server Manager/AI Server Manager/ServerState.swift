//
//  ServerState.swift
//  AI Server Manager
//
//  Created by Helga Moore on 18/09/2026.
//

import Foundation

enum ServerState: Equatable {
    case stopped
    case starting
    case idle
    case busy
    case unavailable

    var title: String {
        switch self {
        case .stopped:
            return "Stopped"

        case .starting:
            return "Starting"

        case .idle:
            return "Running"

        case .busy:
            return "Busy"

        case .unavailable:
            return "Unavailable"
        }
    }

    var systemImage: String {
        switch self {
        case .stopped:
            return "stop.circle"

        case .starting:
            return "clock"

        case .idle:
            return "checkmark.circle"

        case .busy:
            return "gearshape.2"

        case .unavailable:
            return "exclamationmark.triangle"
        }
    }
}
