//
//  City.swift
//  DAPathfinder
//
//  Created by Dejan on 25/01/2018.
//  Copyright © 2018 Dejan. All rights reserved.
//

import UIKit

struct City: Equatable
{
    static func ==(lhs: City, rhs: City) -> Bool {
        return lhs.location == rhs.location
    }
    
    let location: CGPoint
    
    func distance(to: City) -> CGFloat {
        return sqrt(pow(to.location.x - self.location.x, 2) + pow(to.location.y - self.location.y, 2))
    }
}
