//
//  GeneticAlgorithm.swift
//  DAPathfinder
//
//  Created by Dejan on 25/01/2018.
//  Copyright © 2018 Dejan. All rights reserved.
//

import CoreGraphics
import Foundation

/// Runs the genetic algorithm for a set of cities.
actor GeneticAlgorithm {
    var populationSize: Int
    var mutationProbability: Double
    var eliteCount: Int
    
    let cities: [City]
    var currentShortestPath: CGFloat = .infinity
    var onNewGeneration: (@MainActor (Route, [Route], CGFloat, Int) -> Void)?
    
    private var population: [Route] = []
    private var evolvingTask: Task<Void, Never>?

    /// Creates a new algorithm instance with the given cities and settings.
    init(withCities: [City], settings: GASettings) {
        self.cities = withCities
        self.populationSize = max(settings.populationSize, 2)
        self.mutationProbability = min(max(settings.mutationProbability, 0), 1)
        self.eliteCount = min(max(settings.eliteCount, 0), self.populationSize)
        self.population = Self.randomPopulation(fromCities: self.cities, populationSize: self.populationSize)
    }

    /// Registers a handler called when a new generation is produced.
    func setOnNewGeneration(
        _ handler: (@MainActor (Route, [Route], CGFloat, Int) -> Void)?
    ) {
        onNewGeneration = handler
    }
    
    private static func randomPopulation(fromCities: [City], populationSize: Int) -> [Route] {
        var result: [Route] = []
        for _ in 0..<populationSize {
            result.append(Route(cities: fromCities.shuffled()))
        }
        return result
    }
    
    private var generation = 1
    
    /// Starts evolving in a background task.
    public func startEvolution() {
        guard evolvingTask == nil else { return }
        guard cities.count >= 2, populationSize >= 2 else { return }

        let onNewGeneration = self.onNewGeneration
        evolvingTask = Task.detached(priority: .background) { [weak self] in
            guard let self else { return }
            await self.runEvolution(onNewGeneration: onNewGeneration)
        }
    }
    
    /// Stops the evolution task if running.
    public func stopEvolution() {
        evolvingTask?.cancel()
        evolvingTask = nil
    }

    private func runEvolution(
        onNewGeneration: (@MainActor (Route, [Route], CGFloat, Int) -> Void)?
    ) async {
        while !Task.isCancelled {
            if Task.isCancelled || population.isEmpty {
                break
            }
            
            // Calculate best (minimum) and worst (maximum) distances.
            let bestDistance = population.map { $0.distance }.min() ?? 0
            let worstDistance = population.map { $0.distance }.max() ?? CGFloat.greatestFiniteMagnitude
            
            // Compute the fitness values for the generation.
            let fitnessValues = population.map {
                $0.normalizedFitness(bestDistance: bestDistance, worstDistance: worstDistance)
            }
            let totalFitness = fitnessValues.reduce(0, +)
            let fitnessEntries = Array(zip(population, fitnessValues))
            
            // Sort the population by fitness in descending order.
            let currentGeneration = fitnessEntries
                .sorted { $0.1 > $1.1 }
                .map { $0.0 }
            
            // Preserve the elite individuals directly.
            let safeEliteCount = min(eliteCount, currentGeneration.count)
            var nextGeneration = Array(currentGeneration.prefix(safeEliteCount))
            
            // Fill the rest of the population using roulette wheel selection, crossover, and mutation.
            while nextGeneration.count < population.count {
                if totalFitness <= 0 {
                    nextGeneration.append(contentsOf: Self.randomPopulation(fromCities: cities, populationSize: populationSize))
                    nextGeneration = Array(nextGeneration.prefix(population.count))
                    break
                }

                // Select two parents using the roulette wheel selection function.
                if let parent1 = selectParent(from: fitnessEntries, totalFitness: totalFitness),
                   let parent2 = selectParent(from: fitnessEntries, totalFitness: totalFitness) {
                    
                    // Combine the two parents to create a child.
                    let child = produceOffspring(firstParent: parent1, secondParent: parent2)
                    
                    // Mutate the child based on the mutation rate.
                    let mutatedChild = mutate(child: child)
                    
                    nextGeneration.append(mutatedChild)
                }
            }
            
            population = nextGeneration
            
            let sortedPopulation = population
                .sorted { $0.distance < $1.distance }
            if let bestRoute = sortedPopulation.first {
                let topRoutes = Array(sortedPopulation.prefix(11))
                let nextBestRoutes = Array(topRoutes.dropFirst())
                currentShortestPath = bestRoute.distance
                if generation == 1 || generation % 2 == 0 {
                    if !Task.isCancelled {
                        await onNewGeneration?(bestRoute, nextBestRoutes, bestRoute.distance, generation)
                    }
                }
            }
            generation += 1
            await Task.yield()
            try? await Task.sleep(nanoseconds: 1_000_000)
        }

        evolvingTask = nil
    }

    /// Selects a parent using roulette-wheel selection.
    func selectParent(
        from generation: [(Route, CGFloat)],
        totalFitness: CGFloat
    ) -> Route? {
        guard !generation.isEmpty && totalFitness > 0 else { return nil }
        
        // Generate a random threshold between 0 and totalFitness.
        let randomThreshold = CGFloat.random(in: 0..<totalFitness)
        
        // Accumulate fitness and select the route where the threshold is exceeded.
        var cumulativeFitness: CGFloat = 0
        for entry in generation {
            cumulativeFitness += entry.1
            if cumulativeFitness >= randomThreshold {
                return entry.0
            }
        }
        
        // Fallback: return the last route.
        return generation.last?.0
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
        if Double.random(in: 0..<1) < mutationProbability {
            let firstIdx = Int.random(in: 0..<child.cities.count)
            let secondIdx = Int.random(in: 0..<child.cities.count)
            var cities = child.cities
            cities.swapAt(firstIdx, secondIdx)
            
            return Route(cities: cities)
        }
        
        return child
    }
}
