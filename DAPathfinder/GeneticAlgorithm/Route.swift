//
//  Route.swift
//  DAPathfinder
//
//  Created by Dejan on 25/01/2018.
//  Copyright © 2018 Dejan. All rights reserved.
//

import UIKit

class Route
{
    let cities: [City]
    
    private var _distance: CGFloat?
    var distance: CGFloat {
        if _distance == nil {
            _distance = calculateDistance()
        }
        return _distance ?? 0.0
    }
    
    init(cities: [City]) {
        self.cities = cities
    }
    
    private func calculateDistance() -> CGFloat {
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
