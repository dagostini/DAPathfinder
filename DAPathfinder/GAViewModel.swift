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

/// Snapshot of a city for history persistence.
struct HistoryCity: Codable, Hashable {
    let id: UUID
    let x: Double
    let y: Double

    init(id: UUID, x: Double, y: Double) {
        self.id = id
        self.x = x
        self.y = y
    }

    init(city: City) {
        self.id = city.id
        self.x = Double(city.location.x)
        self.y = Double(city.location.y)
    }

    var location: CGPoint {
        CGPoint(x: x, y: y)
    }

    var city: City {
        City(id: id, location: location)
    }
}

/// Snapshot of a route for history persistence.
struct HistoryRoute: Codable, Hashable {
    let cityIDs: [UUID]

    init(cityIDs: [UUID]) {
        self.cityIDs = cityIDs
    }

    init(route: Route) {
        self.cityIDs = route.cities.map { $0.id }
    }
}

/// Persisted history entry representing a past execution.
struct HistoryEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let createdAt: Date
    let settings: GASettings
    let cities: [HistoryCity]
    let bestRoute: HistoryRoute?
    let nextBestRoutes: [HistoryRoute]
    let shortestDistance: Double?
    let generation: Int
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
    /// History of past executions (most recent first).
    @Published private(set) var history: [HistoryEntry] = []
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
    private var currentCities: [City] = []
    private let settingsKey = "GASettings.v1"
    private let historyKey = "GAHistory.v1"
    private let historyMaxEntries = 50
    private let populationMin = 2
    private let populationMax = 2000
    private let eliteMin = 0
    private let eliteMax = 200
    private let mutationMax = 0.05
    private let uiUpdateInterval: CFTimeInterval = 1.0 / 30.0
    private var lastUIUpdate: CFTimeInterval = 0

    init() {
        loadSettings()
        loadHistory()
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
        currentCities = cities
        let algorithm = GeneticAlgorithm(withCities: cities, settings: settings)
        geneticAlgorithm = algorithm
        bestRoute = nil
        nextBestRoutes = []
        shortestDistance = nil
        generation = 0
        isEvolving = true
        lastUIUpdate = 0
        Task {
            await algorithm.setOnNewGeneration { [weak self] route, nextBestRoutes, shortestDistance, generation in
                guard let self else { return }
                let now = CFAbsoluteTimeGetCurrent()
                let previousShortest = self.shortestDistance ?? .infinity
                let improved = shortestDistance < previousShortest
                let shouldUpdate = generation == 1 || improved || (now - lastUIUpdate) >= uiUpdateInterval
                guard shouldUpdate else { return }
                lastUIUpdate = now
                self.bestRoute = route
                self.nextBestRoutes = self.showTopRoutes ? nextBestRoutes : []
                self.shortestDistance = shortestDistance
                self.generation = generation
            }
            await algorithm.startEvolution()
        }
    }

    /// Stops the current evolution task and clears the running state.
    func stopEvolution() {
        if isEvolving {
            recordHistoryIfNeeded()
        }
        if let geneticAlgorithm {
            Task {
                await geneticAlgorithm.stopEvolution()
            }
        }
        geneticAlgorithm = nil
        isEvolving = false
        lastUIUpdate = 0
    }

    /// Clears all locations and resets computed state.
    func clear() {
        stopEvolution()
        locations.removeAll()
        bestRoute = nil
        nextBestRoutes = []
        shortestDistance = nil
        generation = 0
        currentCities = []
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

    /// Loads a historical run into the current state.
    func loadHistory(_ entry: HistoryEntry) {
        stopEvolution()
        let restoredCities = entry.cities.map { $0.city }
        let citiesByID = Dictionary(uniqueKeysWithValues: restoredCities.map { ($0.id, $0) })

        locations = entry.cities.map { $0.location }
        currentCities = restoredCities
        bestRoute = restoreRoute(from: entry.bestRoute, citiesByID: citiesByID)
        nextBestRoutes = entry.nextBestRoutes.compactMap { restoreRoute(from: $0, citiesByID: citiesByID) }
        shortestDistance = entry.shortestDistance.map { CGFloat($0) } ?? bestRoute?.distance
        generation = entry.generation
        settings = normalize(entry.settings)
    }

    /// Deletes history entries at the specified offsets.
    func deleteHistory(at offsets: IndexSet) {
        history.remove(atOffsets: offsets)
        persistHistory()
    }

    /// Clears the entire history.
    func clearHistory() {
        history.removeAll()
        persistHistory()
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

    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: historyKey),
              let decoded = try? JSONDecoder().decode([HistoryEntry].self, from: data) else {
            history = []
            return
        }
        history = decoded
    }

    private func persistHistory() {
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: historyKey)
        }
    }

    private func recordHistoryIfNeeded() {
        guard currentCities.count > 1 else { return }
        guard generation > 0 || bestRoute != nil else { return }

        let entry = HistoryEntry(
            id: UUID(),
            createdAt: Date(),
            settings: settings,
            cities: currentCities.map { HistoryCity(city: $0) },
            bestRoute: bestRoute.map { HistoryRoute(route: $0) },
            nextBestRoutes: nextBestRoutes.map { HistoryRoute(route: $0) },
            shortestDistance: shortestDistance.map { Double($0) },
            generation: generation
        )
        history.insert(entry, at: 0)
        if history.count > historyMaxEntries {
            history = Array(history.prefix(historyMaxEntries))
        }
        persistHistory()
    }

    private func restoreRoute(
        from snapshot: HistoryRoute?,
        citiesByID: [UUID: City]
    ) -> Route? {
        guard let snapshot else { return nil }
        let restoredCities = snapshot.cityIDs.compactMap { citiesByID[$0] }
        guard restoredCities.count == snapshot.cityIDs.count else { return nil }
        return Route(cities: restoredCities)
    }

    private func normalize(_ settings: GASettings) -> GASettings {
        var normalized = settings
        normalized.populationSize = min(max(settings.populationSize, populationMin), populationMax)
        normalized.eliteCount = min(max(settings.eliteCount, eliteMin), min(eliteMax, normalized.populationSize))
        normalized.mutationProbability = min(max(settings.mutationProbability, 0), mutationMax)
        return normalized
    }
}
