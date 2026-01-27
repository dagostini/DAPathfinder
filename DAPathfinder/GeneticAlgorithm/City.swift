//
//  City.swift
//  DAPathfinder
//
//  Created by Dejan on 25/01/2018.
//  Copyright © 2018 Dejan. All rights reserved.
//

import CoreGraphics
import Foundation

/// A city (point) used by the genetic algorithm.
struct City: Equatable, Sendable {
    let id: UUID
    let location: CGPoint

    /// Creates a city with a stable identifier and position.
    init(id: UUID = UUID(), location: CGPoint) {
        self.id = id
        self.location = location
    }

    /// Computes the Euclidean distance to another city.
    func distance(to: City) -> CGFloat {
        sqrt(pow(to.location.x - location.x, 2) + pow(to.location.y - location.y, 2))
    }

    static func == (lhs: City, rhs: City) -> Bool {
        lhs.id == rhs.id
    }
}
