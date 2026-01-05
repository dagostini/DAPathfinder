//
//  GeneticAlgorithmSettings.swift
//  DAPathfinder
//
//  Created by Claude on 2026-01-05.
//  Copyright © 2026 Domenico. All rights reserved.
//

import Foundation

class GeneticAlgorithmSettings {
    static let shared = GeneticAlgorithmSettings()

    // Notification name for settings changes
    static let didUpdateSettingsNotification = Notification.Name("GeneticAlgorithmSettingsDidUpdate")

    // UserDefaults keys
    private enum Keys {
        static let populationSize = "populationSize"
        static let mutationProbability = "mutationProbability"
        static let eliteSize = "eliteSize"
    }

    // Default values (match current hardcoded values)
    private let defaultPopulationSize = 500
    private let defaultMutationProbability = 0.015
    private let defaultEliteSize = 10

    // Validation ranges
    private let populationSizeRange = 10...2000
    private let mutationProbabilityRange = 0.001...0.5
    private let eliteSizeRange = 1...50

    // Properties with UserDefaults persistence
    var populationSize: Int {
        get {
            let value = UserDefaults.standard.integer(forKey: Keys.populationSize)
            return value > 0 ? value : defaultPopulationSize
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.populationSize)
        }
    }

    var mutationProbability: Double {
        get {
            let value = UserDefaults.standard.double(forKey: Keys.mutationProbability)
            return value > 0 ? value : defaultMutationProbability
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.mutationProbability)
        }
    }

    var eliteSize: Int {
        get {
            let value = UserDefaults.standard.integer(forKey: Keys.eliteSize)
            return value > 0 ? value : defaultEliteSize
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.eliteSize)
        }
    }

    private init() {
        // Initialize with defaults if not set
        if UserDefaults.standard.object(forKey: Keys.populationSize) == nil {
            resetToDefaults()
        }
    }

    // Validation result
    enum ValidationError: Error {
        case populationSizeTooSmall
        case populationSizeTooLarge
        case mutationProbabilityTooSmall
        case mutationProbabilityTooLarge
        case eliteSizeTooSmall
        case eliteSizeTooLarge
        case eliteSizeGreaterThanPopulation

        var localizedDescription: String {
            switch self {
            case .populationSizeTooSmall:
                return "Population size must be at least 10"
            case .populationSizeTooLarge:
                return "Population size must be at most 2000"
            case .mutationProbabilityTooSmall:
                return "Mutation probability must be at least 0.001"
            case .mutationProbabilityTooLarge:
                return "Mutation probability must be at most 0.5"
            case .eliteSizeTooSmall:
                return "Elite size must be at least 1"
            case .eliteSizeTooLarge:
                return "Elite size must be at most 50"
            case .eliteSizeGreaterThanPopulation:
                return "Elite size must be less than population size"
            }
        }
    }

    // Validate proposed settings
    func validate(populationSize: Int, mutationProbability: Double, eliteSize: Int) throws {
        // Validate population size
        if populationSize < populationSizeRange.lowerBound {
            throw ValidationError.populationSizeTooSmall
        }
        if populationSize > populationSizeRange.upperBound {
            throw ValidationError.populationSizeTooLarge
        }

        // Validate mutation probability
        if mutationProbability < mutationProbabilityRange.lowerBound {
            throw ValidationError.mutationProbabilityTooSmall
        }
        if mutationProbability > mutationProbabilityRange.upperBound {
            throw ValidationError.mutationProbabilityTooLarge
        }

        // Validate elite size
        if eliteSize < eliteSizeRange.lowerBound {
            throw ValidationError.eliteSizeTooSmall
        }
        if eliteSize > eliteSizeRange.upperBound {
            throw ValidationError.eliteSizeTooLarge
        }

        // Cross-validation: elite size must be less than population size
        if eliteSize >= populationSize {
            throw ValidationError.eliteSizeGreaterThanPopulation
        }
    }

    // Update all settings at once and post notification
    func updateSettings(populationSize: Int, mutationProbability: Double, eliteSize: Int) throws {
        try validate(populationSize: populationSize, mutationProbability: mutationProbability, eliteSize: eliteSize)

        self.populationSize = populationSize
        self.mutationProbability = mutationProbability
        self.eliteSize = eliteSize

        NotificationCenter.default.post(name: GeneticAlgorithmSettings.didUpdateSettingsNotification, object: nil)
    }

    // Reset to default values
    func resetToDefaults() {
        populationSize = defaultPopulationSize
        mutationProbability = defaultMutationProbability
        eliteSize = defaultEliteSize
    }
}
