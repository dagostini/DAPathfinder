//
//  AlgorithmRunner.swift
//  DAPathfinder
//
//  Created by Claude on 2026-01-05.
//  Copyright © 2026 Domenico. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
class AlgorithmRunner: ObservableObject {
    @Published var currentRoute: Route?
    @Published var generation: Int = 0
    @Published var isRunning: Bool = false

    private var algorithm: GeneticAlgorithm?

    func start(with cities: [City], settings: GeneticAlgorithmSettings) {
        // Stop any existing algorithm first
        stop()

        // Reset state
        generation = 0
        currentRoute = nil
        isRunning = true

        // Create algorithm with settings
        algorithm = GeneticAlgorithm(
            withCities: cities,
            populationSize: settings.populationSize,
            mutationProbability: settings.mutationProbability,
            eliteSize: settings.eliteSize
        )

        // Set callback to update UI
        algorithm?.onNewGeneration = { [weak self] route, gen in
            Task { @MainActor in
                self?.currentRoute = route
                self?.generation = gen
            }
        }

        // Start evolution
        algorithm?.startEvolution()
    }

    func stop() {
        algorithm?.stopEvolution()
        algorithm = nil
        isRunning = false
    }

    func reset() {
        stop()
        generation = 0
        currentRoute = nil
    }
}
