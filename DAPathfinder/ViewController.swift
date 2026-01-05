//
//  ViewController.swift
//  DAPathfinder
//
//  Created by Dejan on 25/01/2018.
//  Copyright © 2018 Dejan. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var citiesView: UIView!
    @IBOutlet weak var generationLabel: UILabel!
    
    var locations: [CGPoint] = []
    
    var geneticAlgorithm: GeneticAlgorithm?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Observe settings changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsDidUpdate),
            name: GeneticAlgorithmSettings.didUpdateSettingsNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func settingsDidUpdate() {
        // Reset algorithm state when settings change, but preserve cities
        resetAlgorithmState(preserveCities: true)
    }

    private func resetAlgorithmState(preserveCities: Bool) {
        // Stop any running algorithm
        geneticAlgorithm?.stopEvolution()
        geneticAlgorithm = nil

        // Reset generation counter
        generationLabel.text = "Generation: 0"

        if preserveCities {
            // Clear routes but keep cities
            drawCities()
        } else {
            // Clear everything
            locations.removeAll()
            citiesView.layer.sublayers?.removeAll()
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        if citiesView.point(inside: touch.location(in: citiesView), with: event) {
            let location = touch.location(in: citiesView)
            locations.append(location)
            
            drawCities()
            
        }
    }
    
    private func drawCities() {
        
        self.citiesView.layer.sublayers?.removeAll()
        
        self.locations.forEach { (location) in
            let circle = UIBezierPath.init(arcCenter: location, radius: 5, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
            let circleLayer = CAShapeLayer()
            circleLayer.path = circle.cgPath
            circleLayer.fillColor = UIColor.red.cgColor
            circleLayer.strokeColor = UIColor.red.cgColor
            self.citiesView.layer.addSublayer(circleLayer)
        }
    }
    
    private func drawRoute(route: Route) {
        guard let firstCity = route.cities.first else { return }
        
        var otherCities = route.cities
        otherCities.remove(at: 0)
        
        drawCities()
        
        DispatchQueue.main.async {
            let path = UIBezierPath()

            path.move(to: firstCity.location)
            otherCities.forEach { (city) in
                path.addLine(to: city.location)
            }
            path.addLine(to: firstCity.location)

            let pathLayer = CAShapeLayer()
            pathLayer.path = path.cgPath
            pathLayer.fillColor = UIColor.clear.cgColor
            pathLayer.strokeColor = UIColor.black.cgColor
            pathLayer.lineWidth = 1
            self.citiesView.layer.addSublayer(pathLayer)
        }
    }

    @IBAction func onStart(_ sender: Any) {
        // Stop any existing algorithm first to prevent race condition
        geneticAlgorithm?.stopEvolution()

        // Get current settings
        let settings = GeneticAlgorithmSettings.shared

        // Create new algorithm with current settings
        geneticAlgorithm = GeneticAlgorithm(
            withCities: locations.map { City(location: $0) },
            populationSize: settings.populationSize,
            mutationProbability: settings.mutationProbability,
            eliteSize: settings.eliteSize
        )

        geneticAlgorithm?.onNewGeneration = {
            (route, generation) in
            DispatchQueue.main.async {
                self.generationLabel.text = "Generation: \(generation)"
                self.drawRoute(route: route)
            }
        }

        geneticAlgorithm?.startEvolution()
    }
    
    @IBAction func onClear(_ sender: Any) {
        resetAlgorithmState(preserveCities: false)
    }
    
    @IBAction func onStop(_ sender: Any) {
        geneticAlgorithm?.stopEvolution()
    }
}
