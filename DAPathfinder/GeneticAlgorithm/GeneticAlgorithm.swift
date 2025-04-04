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
    var currentShortestPath: CGFloat = .infinity
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
                
                // Calculate best (minimum) and worst (maximum) distances.
                let bestDistance = self.population.map { $0.distance }.min() ?? 0
                let worstDistance = self.population.map { $0.distance }.max() ?? CGFloat.greatestFiniteMagnitude
                
                // Compute the total fitness for the generation.
                let totalFitness = self.population.reduce(0) { sum, route in
                    sum + route.normalizedFitness(bestDistance: bestDistance, worstDistance: worstDistance)
                }
                
                // Sort the population by fitness in descending order.
                let sortByFitnessDESC: (Route, Route) -> Bool = { $0.normalizedFitness(bestDistance: bestDistance, worstDistance: worstDistance) > $1.normalizedFitness(bestDistance: bestDistance, worstDistance: worstDistance) }
                let currentGeneration = self.population.sorted(by: sortByFitnessDESC)
                
                // Preserve the elite individuals directly.
                var nextGeneration = Array(currentGeneration.prefix(10))
                
                // Fill the rest of the population using roulette wheel selection, crossover, and mutation.
                while nextGeneration.count < self.population.count {
                    // Select two parents using the roulette wheel selection function.
                    if let parent1 = self.selectParent(from: self.population, bestDistance: bestDistance, worstDistance: worstDistance, totalFitness: totalFitness),
                       let parent2 = self.selectParent(from: self.population, bestDistance: bestDistance, worstDistance: worstDistance, totalFitness: totalFitness) {
                        
                        // Combine the two parents to create a child.
                        let child = self.produceOffspring(firstParent: parent1, secondParent: parent2)
                        
                        // Mutate the child based on the mutation rate.
                        let mutatedChild = self.mutate(child: child)
                        
                        nextGeneration.append(mutatedChild)
                    }
                }
                
                self.population = nextGeneration
                
                // TODO: Don't forget to demo the shortest route in a generation!
                if let bestRoute = self.population.sorted(by: sortByFitnessDESC).first {
                    self.currentShortestPath = bestRoute.distance
                    self.onNewGeneration?(bestRoute, self.generation)
                }
                self.generation += 1
            }
        }
    }
    
    public func stopEvolution() {
        evolving = false
    }

    func selectParent(
        from generation: [Route],
        bestDistance: CGFloat,
        worstDistance: CGFloat,
        totalFitness: CGFloat
    ) -> Route? {
        guard !generation.isEmpty && totalFitness > 0 else { return nil }
        
        // Generate a random threshold between 0 and totalFitness.
        let randomThreshold = CGFloat.random(in: 0..<totalFitness)
        
        // Accumulate fitness and select the route where the threshold is exceeded.
        var cumulativeFitness: CGFloat = 0
        for route in generation {
            cumulativeFitness += route.normalizedFitness(bestDistance: bestDistance, worstDistance: worstDistance)
            if cumulativeFitness >= randomThreshold {
                return route
            }
        }
        
        // Fallback: return the last route.
        return generation.last
    }

    private func produceOffspring(firstParent: Route, secondParent: Route) -> Route {
        let count = firstParent.cities.count
        // Ensure there are at least 2 cities to avoid trivial crossover
        guard count > 1 else { return firstParent }
        
        // Choose two random cut points ensuring start < end
        let start = Int.random(in: 0..<count)
        let end = Int.random(in: start..<count)
        
        // Initialize offspring with optional cities
        var offspring = Array<City?>(repeating: nil, count: count)
        
        // Copy a segment from firstParent between start and end indices
        for i in start..<end {
            offspring[i] = firstParent.cities[i]
        }
        
        // Fill in remaining positions with cities from secondParent in order
        var currentIndex = end
        for city in secondParent.cities {
            // Skip if the city is already included
            if offspring.contains(where: { $0 == city }) { continue }
            
            // Find next empty slot, wrapping around if necessary
            while offspring[currentIndex] != nil {
                currentIndex = (currentIndex + 1) % count
            }
            offspring[currentIndex] = city
        }
        
        // Unwrap the optional array into a non-optional array of cities
        return Route(cities: offspring.compactMap { $0 })
    }

    
    private func mutate(child: Route) -> Route {
        if self.mutationProbability >= Double(Double(arc4random()) / Double(UINT32_MAX)) {
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
