//
//  GeneticAlgorithm.swift
//  DAPathfinder
//
//  Created by Dejan on 25/01/2018.
//  Copyright © 2018 Dejan. All rights reserved.
//

import UIKit

class GeneticAlgorithm
{
    var populationSize = 500
    let mutationProbability = 0.015
    
    let cities: [City]
    var onNewGeneration: ((Route, Int) -> ())?
    
    private var population: [Route] = []

    init(withCities: [City]) {
        self.cities = withCities
        self.population = self.randomPopulation(fromCities: self.cities)
    }
    
    private func randomPopulation(fromCities: [City]) -> [Route] {
        var result: [Route] = []
        for _ in 0..<populationSize {
            let randomCities = fromCities.shuffle()
            result.append(Route(cities: randomCities))
        }
        return result
    }
    
    private var evolving = false
    private var generation = 1
    
    public func startEvolution() {
        evolving = true
        DispatchQueue.global().async {
            while self.evolving {
                
                let currentTotalDistance = self.population.reduce(0.0, { $0 + $1.distance })
                let sortByFitnessDESC: (Route, Route) -> Bool = { $0.fitness(withTotalDistance: currentTotalDistance) > $1.fitness(withTotalDistance: currentTotalDistance) }
                let currentGeneration = self.population.sorted(by: sortByFitnessDESC)
                
                var nextGeneration: [Route] = []
                
                for _ in 0..<self.populationSize {
                    guard
                        let parentOne = self.getParent(fromGeneration: currentGeneration, withTotalDistance: currentTotalDistance),
                        let parentTwo = self.getParent(fromGeneration: currentGeneration, withTotalDistance: currentTotalDistance)
                        else { continue }
                    
                    let child = self.produceOffspring(firstParent: parentOne, secondParent: parentTwo)
                    let finalChild = self.mutate(child: child)
                    
                    nextGeneration.append(finalChild)
                }
                self.population = nextGeneration
                
                if let bestRoute = self.population.sorted(by: sortByFitnessDESC).first {
                    self.onNewGeneration?(bestRoute, self.generation)
                }
                self.generation += 1
            }
        }
    }
    
    public func stopEvolution() {
        evolving = false
    }
    
    private func getParent(fromGeneration generation: [Route], withTotalDistance totalDistance: CGFloat) -> Route? {
        let fitness = CGFloat(arc4random() / UINT32_MAX)
        
        var currentFitness: CGFloat = 0.0
        var result: Route?
        generation.forEach { (route) in
            if currentFitness <= fitness {
                currentFitness += route.fitness(withTotalDistance: totalDistance)
                result = route
            }
        }
        
        return result
    }
    
    private func produceOffspring(firstParent: Route, secondParent: Route) -> Route {
        let slice: Int = Int(arc4random_uniform(UInt32(firstParent.cities.count)))
        var cities: [City] = Array(firstParent.cities[0..<slice])
        
        var idx = slice
        while cities.count < secondParent.cities.count {
            let city = secondParent.cities[idx]
            if cities.contains(city) == false {
                cities.append(city)
            }
            idx = (idx + 1) % secondParent.cities.count
        }
        
        return Route(cities: cities)
    }
    
    private func mutate(child: Route) -> Route {
        if self.mutationProbability <= Double(Double(arc4random()) / Double(UINT32_MAX)) {
            let firstIdx = Int(arc4random_uniform(UInt32(child.cities.count)))
            let secondIdx = Int(arc4random_uniform(UInt32(child.cities.count)))
            
            var cities = child.cities
            cities.swapAt(firstIdx, secondIdx)
            
            return Route(cities: cities)
        }
        
        return child
    }
}

extension Array {
    public func shuffle() -> [Element] {
        return sorted(by: { (_, _) -> Bool in
            return arc4random() < arc4random()
        })
    }
}
