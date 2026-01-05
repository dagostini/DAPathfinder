//
//  DAPathfinderApp.swift
//  DAPathfinder
//
//  Created by Claude on 2026-01-05.
//  Copyright © 2026 agostini.tech. All rights reserved.
//

import SwiftUI

@main
struct DAPathfinderApp: App {
    // Use singleton directly instead of @StateObject
    // Settings persist via UserDefaults, so singleton pattern is appropriate
    private let settings = GeneticAlgorithmSettings.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
        }
    }
}
