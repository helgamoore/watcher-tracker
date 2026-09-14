//
//  AppState.swift
//  WatcherTracker
//
//  Created by Helga Moore on 14/09/2026.
//

import Foundation
import Combine

final class AppState: ObservableObject {
    @Published var lastReport: WatcherReport?
}
