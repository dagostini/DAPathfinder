//
//  GeneticAlgorithm.swift
//  DAPathfinder
//
//  Created by Dejan on 25/01/2018.
//  Copyright © 2018 Dejan. All rights reserved.
//

import Foundation
import CoreGraphics

/// A genetic algorithm implementation for solving the Traveling Salesman Problem (TSP).
///
/// This class uses evolutionary computation to find optimal or near-optimal routes through a set of cities.
/// The algorithm maintains a population of route candidates and evolves them over generations using:
/// - **Selection**: Roulette wheel selection based on normalized fitness
/// - **Crossover**: Order crossover (OX) to combine parent routes
/// - **Mutation**: Random swap mutation
/// - **Elitism**: Preserving the best routes across generations
class GeneticAlgorithm {
    // MARK: - Configuration Properties

    /// The number of routes in each generation.
    var populationSize: Int

    /// Probability (0.0 to 1.0) that a route will undergo mutation.
    var mutationProbability: Double

    /// Number of best routes to preserve unchanged in each generation.
    var eliteSize: Int

    // MARK: - Problem Data

    /// The set of cities to find an optimal route through.
    let cities: [City]

    // MARK: - Evolution State

    /// The shortest path distance found in the current generation.
    var currentShortestPath: CGFloat = .infinity

    /// Callback invoked after each generation with top 5 routes, all-time best route, and generation number.
    var onNewGeneration: (([Route], Route?, Int) -> ())?

    /// Callback invoked when evolution stops (either manually or when complete).
    var onEvolutionStopped: (() -> ())?

    /// The current population of routes being evolved.
    private var population: [Route] = []

    /// The best route ever found across all generations.
    private var allTimeBestRoute: Route?

    /// Dispatch queue for thread-safe access to evolution state.
    private let evolutionQueue = DispatchQueue(label: "com.dapathfinder.evolution")

    /// Internal evolving flag (access via thread-safe computed property).
    private var _evolving = false

    /// Thread-safe flag indicating whether evolution is currently running.
    private var evolving: Bool {
        get { evolutionQueue.sync { _evolving } }
        set { evolutionQueue.sync { _evolving = newValue } }
    }

    /// Helper structure to cache fitness calculations for a generation.
    /// Prevents redundant fitness computations (3-5x performance improvement).
    private struct RouteWithFitness {
        let route: Route
        let fitness: CGFloat
    }

    /// Creates a new genetic algorithm instance for solving the TSP.
    ///
    /// - Parameters:
    ///   - withCities: The cities to find an optimal route through
    ///   - populationSize: Number of routes in each generation (default: 500)
    ///   - mutationProbability: Chance of mutation (0.0-1.0, default: 0.015)
    ///   - eliteSize: Number of best routes to preserve each generation (default: 10)
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

    /// Generates an initial random population of routes.
    ///
    /// - Parameter fromCities: The cities to create random routes from
    /// - Returns: An array of randomly shuffled routes
    private func randomPopulation(fromCities: [City]) -> [Route] {
        var result: [Route] = []
        for _ in 0..<populationSize {
            let randomCities = fromCities.shuffled()
            result.append(Route(cities: randomCities))
        }
        return result
    }

    /// The current generation number (increments with each evolution cycle).
    private var generation = 1

    /// Starts the evolutionary process on a background thread.
    ///
    /// The algorithm will run continuously until `stopEvolution()` is called.
    /// After each generation, `onNewGeneration` callback is invoked with the top 5 routes
    /// and the all-time best route found so far.
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

    /// Stops the evolutionary process.
    ///
    /// Sets the evolving flag to false, which will cause the evolution loop to exit
    /// after the current generation completes. The `onEvolutionStopped` callback
    /// will be invoked when evolution fully stops.
    public func stopEvolution() {
        evolving = false
    }

    /// Selects a parent route using roulette wheel selection.
    ///
    /// Routes with higher fitness have a proportionally higher chance of being selected.
    /// This implements fitness-proportionate selection where the probability of selecting
    /// a route is proportional to its fitness relative to the total population fitness.
    ///
    /// - Parameters:
    ///   - generation: The current generation with cached fitness values
    ///   - totalFitness: Sum of all fitness values in the generation
    /// - Returns: A selected route, or nil if generation is empty or totalFitness is 0
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

    /// Creates a child route by combining two parent routes using Order Crossover (OX).
    ///
    /// Order Crossover preserves the relative order of cities from both parents:
    /// 1. Select a random segment from the first parent
    /// 2. Copy this segment to the child at the same positions
    /// 3. Fill remaining positions with cities from the second parent in order,
    ///    skipping cities already included from the first parent
    ///
    /// This ensures the child is a valid route (all cities visited exactly once)
    /// while inheriting subsequence patterns from both parents.
    ///
    /// - Parameters:
    ///   - firstParent: The first parent route
    ///   - secondParent: The second parent route
    /// - Returns: A new child route combining characteristics of both parents
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


    /// Applies random swap mutation to a route.
    ///
    /// With probability `mutationProbability`, randomly selects two cities in the route
    /// and swaps their positions. This introduces genetic diversity and helps prevent
    /// premature convergence to local optima.
    ///
    /// - Parameter child: The route to potentially mutate
    /// - Returns: Either the mutated route (if mutation occurred) or the original route
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
