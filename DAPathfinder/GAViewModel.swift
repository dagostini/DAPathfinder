//
//  GAViewModel.swift
//  DAPathfinder
//
//  Created by Codex on 2025-02-08.
//

import CoreGraphics
import Foundation

/// User-adjustable parameters for the genetic algorithm.
///
/// Values are normalized by ``GAViewModel`` before use.
struct GASettings: Codable, Equatable {
    var populationSize: Int
    var mutationProbability: Double
    var eliteCount: Int

    static let `default` = GASettings(
        populationSize: 500,
        mutationProbability: 0.015,
        eliteCount: 10
    )
}

/// Main view model for the app's genetic algorithm UI and persistence.
@MainActor
final class GAViewModel: ObservableObject {
    private struct PersistedSettings: Codable {
        var gaSettings: GASettings
        var showTopRoutes: Bool

        static let `default` = PersistedSettings(
            gaSettings: .default,
            showTopRoutes: true
        )
    }

    /// User-provided city locations in view coordinates.
    @Published private(set) var locations: [CGPoint] = []
    /// Best route from the most recently evaluated generation.
    @Published private(set) var bestRoute: Route?
    /// Additional top routes for visualization.
    @Published private(set) var nextBestRoutes: [Route] = []
    /// Shortest distance for the current best route.
    @Published private(set) var shortestDistance: CGFloat?
    /// Current generation count.
    @Published private(set) var generation: Int = 0
    /// Whether the algorithm is actively evolving.
    @Published private(set) var isEvolving = false
    /// Current algorithm settings (normalized on change).
    @Published var settings: GASettings = .default {
        didSet {
            if oldValue != settings {
                let normalized = normalize(settings)
                if normalized != settings {
                    settings = normalized
                    return
                }
                stopEvolution()
                persistSettings()
            }
        }
    }
    /// Controls whether additional top routes are rendered.
    @Published var showTopRoutes: Bool = true {
        didSet {
            if oldValue != showTopRoutes {
                persistSettings()
            }
        }
    }

    private var geneticAlgorithm: GeneticAlgorithm?
    private let settingsKey = "GASettings.v1"
    private let populationMin = 2
    private let populationMax = 2000
    private let eliteMin = 0
    private let eliteMax = 200
    private let mutationMax = 0.05

    init() {
        loadSettings()
    }

    /// Adds a new city location if evolution is not running.
    func addLocation(_ point: CGPoint) {
        guard !isEvolving else { return }
        locations.append(point)
        bestRoute = nil
        nextBestRoutes = []
        shortestDistance = nil
        generation = 0
    }

    /// Starts the genetic algorithm using the current locations and settings.
    func startEvolution() {
        guard locations.count > 1 else { return }
        stopEvolution()

        let cities = locations.map { City(location: $0) }
        let algorithm = GeneticAlgorithm(withCities: cities, settings: settings)
        geneticAlgorithm = algorithm
        bestRoute = nil
        nextBestRoutes = []
        shortestDistance = nil
        generation = 0
        isEvolving = true
        Task {
            await algorithm.setOnNewGeneration { [weak self] route, nextBestRoutes, shortestDistance, generation in
                self?.bestRoute = route
                self?.nextBestRoutes = nextBestRoutes
                self?.shortestDistance = shortestDistance
                self?.generation = generation
            }
            await algorithm.startEvolution()
        }
    }

    /// Stops the current evolution task and clears the running state.
    func stopEvolution() {
        if let geneticAlgorithm {
            Task {
                await geneticAlgorithm.stopEvolution()
            }
        }
        geneticAlgorithm = nil
        isEvolving = false
    }

    /// Clears all locations and resets computed state.
    func clear() {
        stopEvolution()
        locations.removeAll()
        bestRoute = nil
        nextBestRoutes = []
        shortestDistance = nil
        generation = 0
    }

    /// Updates settings and normalizes values into valid ranges.
    func updateSettings(_ update: (inout GASettings) -> Void) {
        var newSettings = settings
        update(&newSettings)
        settings = normalize(newSettings)
    }

    /// Restores default settings and UI toggles.
    func resetSettings() {
        settings = normalize(.default)
        showTopRoutes = true
    }

    private func loadSettings() {
        guard let data = UserDefaults.standard.data(forKey: settingsKey),
              let decoded = try? JSONDecoder().decode(PersistedSettings.self, from: data) else {
            let defaults = PersistedSettings.default
            settings = normalize(defaults.gaSettings)
            showTopRoutes = defaults.showTopRoutes
            return
        }
        settings = normalize(decoded.gaSettings)
        showTopRoutes = decoded.showTopRoutes
    }

    private func persistSettings() {
        let payload = PersistedSettings(gaSettings: settings, showTopRoutes: showTopRoutes)
        if let data = try? JSONEncoder().encode(payload) {
            UserDefaults.standard.set(data, forKey: settingsKey)
        }
    }

    private func normalize(_ settings: GASettings) -> GASettings {
        var normalized = settings
        normalized.populationSize = min(max(settings.populationSize, populationMin), populationMax)
        normalized.eliteCount = min(max(settings.eliteCount, eliteMin), min(eliteMax, normalized.populationSize))
        normalized.mutationProbability = min(max(settings.mutationProbability, 0), mutationMax)
        return normalized
    }
}
