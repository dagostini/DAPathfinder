//
//  GeneticAlgorithmSettings.swift
//  DAPathfinder
//
//  Created by Claude on 2026-01-05.
//  Copyright © 2026 agostini.tech. All rights reserved.
//

import Foundation
import Combine

/// Manages user-configurable settings for the genetic algorithm.
///
/// This singleton class provides persistent storage of algorithm parameters using UserDefaults.
/// All settings are validated before being applied, and changes are automatically
/// published to observers via Combine's `@Published` property wrapper.
class GeneticAlgorithmSettings: ObservableObject {
    /// Shared singleton instance.
    static let shared = GeneticAlgorithmSettings()

    // MARK: - UserDefaults Keys

    /// Keys for storing settings in UserDefaults.
    private enum Keys {
        static let populationSize = "populationSize"
        static let mutationProbability = "mutationProbability"
        static let eliteSize = "eliteSize"
    }

    // MARK: - Default Values

    /// Default population size (number of routes per generation).
    private let defaultPopulationSize = 500

    /// Default mutation probability (1.5% chance per route).
    private let defaultMutationProbability = 0.015

    /// Default elite size (top 10 routes preserved each generation).
    private let defaultEliteSize = 10

    // MARK: - Validation Ranges

    /// Valid range for population size (10 to 2000 routes).
    private let populationSizeRange = 10...2000

    /// Valid range for mutation probability (0.1% to 50%).
    private let mutationProbabilityRange = 0.001...0.5

    /// Valid range for elite size (1 to 50 routes).
    private let eliteSizeRange = 1...50

    // MARK: - Published Properties

    /// Number of routes in each generation.
    /// Automatically persisted to UserDefaults when changed.
    @Published var populationSize: Int {
        didSet {
            UserDefaults.standard.set(populationSize, forKey: Keys.populationSize)
        }
    }

    /// Probability (0.0 to 1.0) that a route will undergo mutation.
    /// Automatically persisted to UserDefaults when changed.
    @Published var mutationProbability: Double {
        didSet {
            UserDefaults.standard.set(mutationProbability, forKey: Keys.mutationProbability)
        }
    }

    /// Number of best routes to preserve unchanged in each generation (elitism).
    /// Automatically persisted to UserDefaults when changed.
    @Published var eliteSize: Int {
        didSet {
            UserDefaults.standard.set(eliteSize, forKey: Keys.eliteSize)
        }
    }

    private init() {
        // Load from UserDefaults or use defaults
        // Use object(forKey:) to distinguish between "not set" and "set to 0"
        if UserDefaults.standard.object(forKey: Keys.populationSize) != nil {
            self.populationSize = UserDefaults.standard.integer(forKey: Keys.populationSize)
        } else {
            self.populationSize = defaultPopulationSize
        }

        if UserDefaults.standard.object(forKey: Keys.mutationProbability) != nil {
            self.mutationProbability = UserDefaults.standard.double(forKey: Keys.mutationProbability)
        } else {
            self.mutationProbability = defaultMutationProbability
        }

        if UserDefaults.standard.object(forKey: Keys.eliteSize) != nil {
            self.eliteSize = UserDefaults.standard.integer(forKey: Keys.eliteSize)
        } else {
            self.eliteSize = defaultEliteSize
        }
    }

    // MARK: - Validation

    /// Errors that can occur during settings validation.
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
            case .populationSizeTooSmall, .populationSizeTooLarge:
                return NSLocalizedString("Validation.PopulationSize", comment: "")
            case .mutationProbabilityTooSmall, .mutationProbabilityTooLarge:
                return NSLocalizedString("Validation.MutationProbability", comment: "")
            case .eliteSizeTooSmall, .eliteSizeTooLarge, .eliteSizeGreaterThanPopulation:
                return NSLocalizedString("Validation.EliteSize", comment: "")
            }
        }
    }

    /// Validates proposed settings without applying them.
    ///
    /// Checks that all values are within their valid ranges and that elite size
    /// is less than population size.
    ///
    /// - Parameters:
    ///   - populationSize: Proposed population size
    ///   - mutationProbability: Proposed mutation probability
    ///   - eliteSize: Proposed elite size
    /// - Throws: `ValidationError` if any parameter is invalid
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

    /// Updates all settings atomically after validation.
    ///
    /// All three settings are validated together before any are applied. If validation
    /// fails, none of the settings are changed. Changes are automatically published
    /// to observers and persisted to UserDefaults.
    ///
    /// - Parameters:
    ///   - populationSize: New population size
    ///   - mutationProbability: New mutation probability
    ///   - eliteSize: New elite size
    /// - Throws: `ValidationError` if any parameter is invalid
    func updateSettings(populationSize: Int, mutationProbability: Double, eliteSize: Int) throws {
        try validate(populationSize: populationSize, mutationProbability: mutationProbability, eliteSize: eliteSize)

        self.populationSize = populationSize
        self.mutationProbability = mutationProbability
        self.eliteSize = eliteSize
    }

    /// Resets all settings to their default values.
    ///
    /// Changes are automatically published to observers and persisted to UserDefaults.
    func resetToDefaults() {
        populationSize = defaultPopulationSize
        mutationProbability = defaultMutationProbability
        eliteSize = defaultEliteSize
    }
}
