//
//  Route.swift
//  DAPathfinder
//
//  Created by Dejan on 25/01/2018.
//  Copyright © 2018 Dejan. All rights reserved.
//

import CoreGraphics

/// A route representing a potential solution to the Traveling Salesman Problem.
///
/// A route is an ordered sequence of cities forming a complete tour that returns
/// to the starting city. The distance is calculated once during initialization
/// for performance (eager evaluation with caching).
struct Route {
    /// The ordered sequence of cities in this route.
    let cities: [City]

    /// The total distance of this route (sum of all city-to-city distances plus return to start).
    /// Calculated once during initialization for performance.
    let distance: CGFloat

    /// Creates a new route from an ordered sequence of cities.
    ///
    /// The distance is calculated eagerly during initialization. For a valid TSP route,
    /// all cities should appear exactly once.
    ///
    /// - Parameter cities: The ordered sequence of cities to visit
    init(cities: [City]) {
        self.cities = cities
        self.distance = Self.calculateDistance(for: cities)
    }

    /// Calculates the total distance of a route.
    ///
    /// Sums the distances between consecutive cities, plus the distance from the last city
    /// back to the first city to complete the tour.
    ///
    /// - Parameter cities: The ordered sequence of cities
    /// - Returns: The total distance of the complete tour
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

    /// Calculates a normalized fitness value for this route relative to the current generation.
    ///
    /// Fitness is inversely proportional to distance (shorter routes = higher fitness).
    /// The fitness is normalized so the best route gets 1.0 and the worst gets 0.0.
    /// An exponent is applied to increase selection pressure, making fitter routes
    /// disproportionately more likely to be selected for reproduction.
    ///
    /// **Formula**: `((worstDistance - distance) / (worstDistance - bestDistance)) ^ exponent`
    ///
    /// - Parameters:
    ///   - bestDistance: The shortest distance in the current generation
    ///   - worstDistance: The longest distance in the current generation
    ///   - exponent: Selection pressure multiplier (higher = more pressure, default: 3.0)
    /// - Returns: A fitness value between 0.0 (worst) and 1.0 (best)
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
