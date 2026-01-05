//
//  AlgorithmRunner.swift
//  DAPathfinder
//
//  Created by Claude on 2026-01-05.
//  Copyright © 2026 agostini.tech. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
class AlgorithmRunner: ObservableObject {
    @Published var top5Routes: [Route] = []
    @Published var allTimeBestRoute: Route?
    @Published var generation: Int = 0
    @Published var isRunning: Bool = false
    @Published var bestDistance: CGFloat = 0

    private var algorithm: GeneticAlgorithm?

    func start(with cities: [City], settings: GeneticAlgorithmSettings) {
        // Stop any existing algorithm first
        stop()

        // Reset state
        generation = 0
        top5Routes = []
        isRunning = true

        // Create algorithm with settings
        algorithm = GeneticAlgorithm(
            withCities: cities,
            populationSize: settings.populationSize,
            mutationProbability: settings.mutationProbability,
            eliteSize: settings.eliteSize
        )

        // Set callback to update UI
        algorithm?.onNewGeneration = { [weak self] top5, allTimeBest, gen in
            Task { @MainActor in
                self?.top5Routes = top5
                self?.allTimeBestRoute = allTimeBest
                self?.generation = gen
                self?.bestDistance = allTimeBest?.distance ?? top5.first?.distance ?? 0
            }
        }

        // Set callback for when evolution stops
        algorithm?.onEvolutionStopped = { [weak self] in
            Task { @MainActor in
                self?.isRunning = false
            }
        }

        // Start evolution
        algorithm?.startEvolution()
    }

    func stop() {
        algorithm?.stopEvolution()
        // Don't set isRunning = false here; wait for onEvolutionStopped callback
        // This prevents race condition
    }

    func reset() {
        stop()
        generation = 0
        top5Routes = []
        allTimeBestRoute = nil
        bestDistance = 0
    }
}
