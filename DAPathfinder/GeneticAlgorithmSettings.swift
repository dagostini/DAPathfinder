//
//  GeneticAlgorithmSettings.swift
//  DAPathfinder
//
//  Created by Claude on 2026-01-05.
//  Copyright © 2026 agostini.tech. All rights reserved.
//

import Foundation
import Combine

class GeneticAlgorithmSettings: ObservableObject {
    static let shared = GeneticAlgorithmSettings()

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

    // Published properties with UserDefaults persistence
    @Published var populationSize: Int {
        didSet {
            UserDefaults.standard.set(populationSize, forKey: Keys.populationSize)
        }
    }

    @Published var mutationProbability: Double {
        didSet {
            UserDefaults.standard.set(mutationProbability, forKey: Keys.mutationProbability)
        }
    }

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
            case .populationSizeTooSmall, .populationSizeTooLarge:
                return NSLocalizedString("Validation.PopulationSize", comment: "")
            case .mutationProbabilityTooSmall, .mutationProbabilityTooLarge:
                return NSLocalizedString("Validation.MutationProbability", comment: "")
            case .eliteSizeTooSmall, .eliteSizeTooLarge, .eliteSizeGreaterThanPopulation:
                return NSLocalizedString("Validation.EliteSize", comment: "")
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

    // Update all settings at once (automatically publishes changes)
    func updateSettings(populationSize: Int, mutationProbability: Double, eliteSize: Int) throws {
        try validate(populationSize: populationSize, mutationProbability: mutationProbability, eliteSize: eliteSize)

        self.populationSize = populationSize
        self.mutationProbability = mutationProbability
        self.eliteSize = eliteSize
    }

    // Reset to default values
    func resetToDefaults() {
        populationSize = defaultPopulationSize
        mutationProbability = defaultMutationProbability
        eliteSize = defaultEliteSize
    }
}
