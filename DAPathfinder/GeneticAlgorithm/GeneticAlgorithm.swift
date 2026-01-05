//
//  GeneticAlgorithm.swift
//  DAPathfinder
//
//  Created by Dejan on 25/01/2018.
//  Copyright © 2018 Dejan. All rights reserved.
//

import Foundation
import CoreGraphics

class GeneticAlgorithm
{
    var populationSize: Int
    var mutationProbability: Double
    var eliteSize: Int

    let cities: [City]
    var currentShortestPath: CGFloat = .infinity
    var onNewGeneration: (([Route], Route?, Int) -> ())?  // top5Routes, allTimeBest, generation
    var onEvolutionStopped: (() -> ())?

    private var population: [Route] = []
    private var allTimeBestRoute: Route?
    private let evolutionQueue = DispatchQueue(label: "com.dapathfinder.evolution")
    private var _evolving = false
    private var evolving: Bool {
        get { evolutionQueue.sync { _evolving } }
        set { evolutionQueue.sync { _evolving = newValue } }
    }

    private struct RouteWithFitness {
        let route: Route
        let fitness: CGFloat
    }

    init(withCities: [City],
         populationSize: Int = 500,
         mutationProbability: Double = 0.015,
         eliteSize: Int = 10) {
        self.populationSize = populationSize
        self.mutationProbability = mutationProbability
        self.eliteSize = eliteSize
        self.cities = withCities
        self.population = self.randomPopulation(fromCities: self.cities)
    }
    
    private func randomPopulation(fromCities: [City]) -> [Route] {
        var result: [Route] = []
        for _ in 0..<populationSize {
            let randomCities = fromCities.shuffled()
            result.append(Route(cities: randomCities))
        }
        return result
    }

    private var generation = 1

    public func startEvolution() {
        evolving = true
        DispatchQueue.global().async {
            while self.evolving {

                // Calculate best (minimum) and worst (maximum) distances.
                let distances = self.population.map { $0.distance }
                let bestDistance = distances.min() ?? 0
                let worstDistance = distances.max() ?? CGFloat.greatestFiniteMagnitude

                // Cache fitness calculations for this generation
                let routesWithFitness = self.population.map { route in
                    RouteWithFitness(
                        route: route,
                        fitness: route.normalizedFitness(bestDistance: bestDistance, worstDistance: worstDistance)
                    )
                }

                // Compute the total fitness for the generation.
                let totalFitness = routesWithFitness.reduce(0) { sum, item in
                    sum + item.fitness
                }

                // Sort the population by fitness in descending order.
                let currentGeneration = routesWithFitness.sorted { $0.fitness > $1.fitness }

                // Preserve the elite individuals directly.
                var nextGeneration = currentGeneration.prefix(self.eliteSize).map { $0.route }

                // Fill the rest of the population using roulette wheel selection, crossover, and mutation.
                while nextGeneration.count < self.population.count {
                    // Select two parents using the roulette wheel selection function.
                    if let parent1 = self.selectParent(from: routesWithFitness, totalFitness: totalFitness),
                       let parent2 = self.selectParent(from: routesWithFitness, totalFitness: totalFitness) {

                        // Combine the two parents to create a child.
                        let child = self.produceOffspring(firstParent: parent1, secondParent: parent2)

                        // Mutate the child based on the mutation rate.
                        let mutatedChild = self.mutate(child: child)

                        nextGeneration.append(mutatedChild)
                    }
                }

                self.population = nextGeneration

                // Report the top routes in this generation
                if let bestRoute = currentGeneration.first?.route {
                    self.currentShortestPath = bestRoute.distance

                    // Track all-time best route
                    if self.allTimeBestRoute == nil || bestRoute.distance < self.allTimeBestRoute!.distance {
                        self.allTimeBestRoute = bestRoute
                    }

                    // Get top 5 routes from current generation
                    let top5Routes = currentGeneration.prefix(5).map { $0.route }

                    // Pass top 5 routes, all-time best, and generation
                    self.onNewGeneration?(top5Routes, self.allTimeBestRoute, self.generation)
                }
                self.generation += 1
            }

            // Notify that evolution has stopped
            self.onEvolutionStopped?()
        }
    }

    public func stopEvolution() {
        evolving = false
    }

    private func selectParent(
        from generation: [RouteWithFitness],
        totalFitness: CGFloat
    ) -> Route? {
        guard !generation.isEmpty && totalFitness > 0 else { return nil }

        // Generate a random threshold between 0 and totalFitness.
        let randomThreshold = CGFloat.random(in: 0..<totalFitness)

        // Accumulate fitness and select the route where the threshold is exceeded.
        var cumulativeFitness: CGFloat = 0
        for item in generation {
            cumulativeFitness += item.fitness
            if cumulativeFitness >= randomThreshold {
                return item.route
            }
        }

        // Fallback: return the last route.
        return generation.last?.route
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
        if Double.random(in: 0...1) < self.mutationProbability {
            let firstIdx = Int.random(in: 0..<child.cities.count)
            let secondIdx = Int.random(in: 0..<child.cities.count)
            var cities = child.cities
            cities.swapAt(firstIdx, secondIdx)

            return Route(cities: cities)
        }

        return child
    }
}
