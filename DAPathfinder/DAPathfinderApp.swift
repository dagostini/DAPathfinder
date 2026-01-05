//
//  DAPathfinderApp.swift
//  DAPathfinder
//
//  Created by Claude on 2026-01-05.
//  Copyright © 2026 Domenico. All rights reserved.
//

import SwiftUI

@main
struct DAPathfinderApp: App {
    @StateObject private var settings = GeneticAlgorithmSettings.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
        }
    }
}
