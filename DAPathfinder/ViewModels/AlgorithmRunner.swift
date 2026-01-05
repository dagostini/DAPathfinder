//
//  AlgorithmRunner.swift
//  DAPathfinder
//
//  Created by Claude on 2026-01-05.
//  Copyright © 2026 agostini.tech. All rights reserved.
//

import Foundation
import SwiftUI

/// Manages the genetic algorithm execution and bridges it to the SwiftUI layer.
///
/// This class runs on the main actor to ensure all UI updates happen on the main thread.
/// It wraps the `GeneticAlgorithm` which runs on a background thread, and provides
/// thread-safe callbacks to update the published properties.
@MainActor
class AlgorithmRunner: ObservableObject {
    // MARK: - Published State

    /// The top 5 routes from the current generation, ordered by quality (best first).
    @Published var top5Routes: [Route] = []

    /// The best route ever found across all generations.
    @Published var allTimeBestRoute: Route?

    /// The current generation number.
    @Published var generation: Int = 0

    /// Whether the algorithm is currently running.
    @Published var isRunning: Bool = false

    /// The distance of the best route (either all-time best or current generation best).
    @Published var bestDistance: CGFloat = 0

    // MARK: - Private Properties

    /// The underlying genetic algorithm instance running on a background thread.
    private var algorithm: GeneticAlgorithm?

    // MARK: - Public Methods

    /// Starts the genetic algorithm with the given cities and settings.
    ///
    /// This method:
    /// 1. Stops any existing algorithm
    /// 2. Resets the state
    /// 3. Creates a new algorithm instance with the provided settings
    /// 4. Sets up callbacks for generation updates and completion
    /// 5. Starts the evolution process on a background thread
    ///
    /// - Parameters:
    ///   - cities: The cities to find an optimal route through
    ///   - settings: Algorithm configuration (population size, mutation rate, elite size)
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

    /// Stops the currently running algorithm.
    ///
    /// Sets the algorithm's evolving flag to false. The `isRunning` state will be
    /// updated to false asynchronously via the `onEvolutionStopped` callback to
    /// prevent race conditions.
    func stop() {
        algorithm?.stopEvolution()
        // Don't set isRunning = false here; wait for onEvolutionStopped callback
        // This prevents race condition
    }

    /// Resets the algorithm state to initial conditions.
    ///
    /// Stops any running algorithm and clears all routes and statistics.
    func reset() {
        stop()
        generation = 0
        top5Routes = []
        allTimeBestRoute = nil
        bestDistance = 0
    }
}
