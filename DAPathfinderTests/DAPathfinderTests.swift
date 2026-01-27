import CoreGraphics
import XCTest
@testable import DAPathfinder

final class DAPathfinderTests: XCTestCase {
    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "GASettings.v1")
    }

    func testCityDistanceIsSymmetric() {
        let cityA = City(location: CGPoint(x: 0, y: 0))
        let cityB = City(location: CGPoint(x: 3, y: 4))

        XCTAssertEqual(cityA.distance(to: cityB), 5, accuracy: 0.0001)
        XCTAssertEqual(cityB.distance(to: cityA), 5, accuracy: 0.0001)
    }

    func testRouteDistanceClosesLoop() {
        let cities = [
            City(location: CGPoint(x: 0, y: 0)),
            City(location: CGPoint(x: 0, y: 1)),
            City(location: CGPoint(x: 1, y: 1)),
            City(location: CGPoint(x: 1, y: 0))
        ]
        let route = Route(cities: cities)

        XCTAssertEqual(route.distance, 4, accuracy: 0.0001)
    }

    func testRouteNormalizedFitnessHandlesEqualDistances() {
        let cities = [
            City(location: CGPoint(x: 0, y: 0)),
            City(location: CGPoint(x: 1, y: 0))
        ]
        let route = Route(cities: cities)

        XCTAssertEqual(route.normalizedFitness(bestDistance: 2, worstDistance: 2), 1, accuracy: 0.0001)
    }

    func testCityEqualityUsesStableIdentifier() {
        let id = UUID()
        let cityA = City(id: id, location: CGPoint(x: 1, y: 1))
        let cityB = City(id: id, location: CGPoint(x: 2, y: 2))
        let cityC = City(location: CGPoint(x: 1, y: 1))

        XCTAssertEqual(cityA, cityB)
        XCTAssertNotEqual(cityA, cityC)
    }

    func testNormalizedFitnessAtBestDistanceIsOne() {
        let cities = [
            City(location: CGPoint(x: 0, y: 0)),
            City(location: CGPoint(x: 0, y: 1)),
            City(location: CGPoint(x: 1, y: 1)),
            City(location: CGPoint(x: 1, y: 0))
        ]
        let route = Route(cities: cities)
        let best = route.distance
        let worst: CGFloat = 10

        XCTAssertEqual(route.normalizedFitness(bestDistance: best, worstDistance: worst), 1, accuracy: 0.0001)
    }

    @MainActor
    func testSettingsResetRestoresDefaults() {
        let viewModel = GAViewModel()

        viewModel.updateSettings { settings in
            settings.populationSize = 123
            settings.eliteCount = 7
            settings.mutationProbability = 0.03
        }
        viewModel.showTopRoutes = false
        viewModel.resetSettings()

        XCTAssertEqual(viewModel.settings, GASettings.default)
        XCTAssertTrue(viewModel.showTopRoutes)
    }

    @MainActor
    func testSettingsNormalizationClampsEliteToPopulation() {
        let viewModel = GAViewModel()

        viewModel.updateSettings { settings in
            settings.populationSize = 10
            settings.eliteCount = 50
        }

        XCTAssertEqual(viewModel.settings.eliteCount, 10)
    }

    @MainActor
    func testAddLocationResetsDerivedState() {
        let viewModel = GAViewModel()

        viewModel.addLocation(CGPoint(x: 10, y: 10))

        XCTAssertEqual(viewModel.locations.count, 1)
        XCTAssertNil(viewModel.bestRoute)
        XCTAssertTrue(viewModel.nextBestRoutes.isEmpty)
        XCTAssertNil(viewModel.shortestDistance)
        XCTAssertEqual(viewModel.generation, 0)
    }

    func testGeneticAlgorithmSelectParentHandlesEmptyFitness() async {
        let cities = [
            City(location: CGPoint(x: 0, y: 0)),
            City(location: CGPoint(x: 1, y: 0))
        ]
        let algorithm = GeneticAlgorithm(withCities: cities, settings: .default)
        let selection = await algorithm.selectParent(from: [], totalFitness: 0)

        XCTAssertNil(selection)
    }

    @MainActor
    func testSettingsNormalizationClampsValues() {
        UserDefaults.standard.removeObject(forKey: "GASettings.v1")
        let viewModel = GAViewModel()

        viewModel.updateSettings { settings in
            settings.populationSize = 1
            settings.eliteCount = 500
            settings.mutationProbability = 10
        }

        XCTAssertEqual(viewModel.settings.populationSize, 2)
        XCTAssertEqual(viewModel.settings.eliteCount, 2)
        XCTAssertEqual(viewModel.settings.mutationProbability, 0.05, accuracy: 0.0001)
    }
}
