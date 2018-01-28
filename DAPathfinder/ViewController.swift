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
            UIColor.black.setStroke()
            path.lineWidth = 1
            
            path.move(to: firstCity.location)
            otherCities.forEach { (city) in
                path.addLine(to: city.location)
            }
            path.addLine(to: firstCity.location)
            
            path.stroke()
            
            let pathLayer = CAShapeLayer()
            pathLayer.path = path.cgPath
            pathLayer.fillColor = UIColor.clear.cgColor
            pathLayer.strokeColor = UIColor.black.cgColor
            self.citiesView.layer.addSublayer(pathLayer)
        }
    }

    @IBAction func onStart(_ sender: Any) {
        geneticAlgorithm = GeneticAlgorithm(withCities: locations.map { City(location: $0) })
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
        locations.removeAll()
        citiesView.layer.sublayers?.removeAll()
        generationLabel.text = "Generation: 0"
    }
    
    @IBAction func onStop(_ sender: Any) {
        geneticAlgorithm?.stopEvolution()
    }
}
