//
//  Route.swift
//  DAPathfinder
//
//  Created by Dejan on 25/01/2018.
//  Copyright © 2018 Dejan. All rights reserved.
//

import CoreGraphics
import Foundation

/// A complete route visiting all cities once, with total distance precomputed.
struct Route: Sendable {
    let cities: [City]
    let distance: CGFloat
    
    /// Creates a route and calculates its total distance.
    init(cities: [City]) {
        self.cities = cities
        self.distance = Self.calculateDistance(for: cities)
    }
    
    private static func calculateDistance(for cities: [City]) -> CGFloat {
        var result: CGFloat = 0.0
        var previousCity: City?
        
        cities.forEach { (city) in
            if let previous = previousCity {
                result += previous.distance(to: city)
            }
            previousCity = city
        }
        
        guard let first = cities.first, let last = cities.last else { return result }
        
        return result + first.distance(to: last)
    }

    /// Returns a normalized fitness value based on the best and worst distances in the generation.
    /// The best route gets a fitness of 1.0, and the worst gets 0.0.
    /// The `exponent` parameter is used to increase selection pressure.
    /// Computes a normalized fitness value in the range 0...1.
    func normalizedFitness(bestDistance: CGFloat, worstDistance: CGFloat, exponent: CGFloat = 3.0) -> CGFloat {
        // If all routes are identical, give a neutral fitness.
        if bestDistance == worstDistance {
            return 1.0
        }
        // Normalize: best -> 1.0, worst -> 0.0.
        let normalized = (worstDistance - distance) / (worstDistance - bestDistance)
        // Apply exponent to increase selection pressure.
        return pow(normalized, exponent)
    }
}
