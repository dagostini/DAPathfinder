//
//  City.swift
//  DAPathfinder
//
//  Created by Dejan on 25/01/2018.
//  Copyright © 2018 Dejan. All rights reserved.
//

import CoreGraphics

/// Represents a city in the Traveling Salesman Problem.
///
/// A city is defined by its 2D location on a canvas. Two cities are considered
/// equal if they have the same location coordinates.
struct City: Equatable {
    static func ==(lhs: City, rhs: City) -> Bool {
        return lhs.location == rhs.location
    }

    /// The position of this city on the 2D canvas.
    let location: CGPoint

    /// Calculates the Euclidean distance to another city.
    ///
    /// Uses the standard distance formula: `√((x₂-x₁)² + (y₂-y₁)²)`
    ///
    /// - Parameter to: The destination city
    /// - Returns: The straight-line distance to the other city
    func distance(to: City) -> CGFloat {
        return sqrt(pow(to.location.x - self.location.x, 2) + pow(to.location.y - self.location.y, 2))
    }
}
