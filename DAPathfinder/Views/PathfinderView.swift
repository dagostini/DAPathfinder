//
//  PathfinderView.swift
//  DAPathfinder
//
//  Created by Claude on 2026-01-05.
//  Copyright © 2026 agostini.tech. All rights reserved.
//

import SwiftUI

struct PathfinderView: View {
    @EnvironmentObject var settings: GeneticAlgorithmSettings
    @StateObject private var algorithmRunner = AlgorithmRunner()
    @State private var locations: [CGPoint] = []

    var body: some View {
        VStack(spacing: 0) {
            // Canvas for drawing cities and routes
            Canvas { context, size in
                // Draw cities as red circles
                for location in locations {
                    let circle = Path { path in
                        path.addEllipse(in: CGRect(
                            x: location.x - 5,
                            y: location.y - 5,
                            width: 10,
                            height: 10
                        ))
                    }
                    context.fill(circle, with: .color(.red))
                }

                // Draw top 5 routes from current generation with decreasing opacity
                // Best route (#1) is darkest, #5 is lightest
                for (index, route) in algorithmRunner.top5Routes.enumerated() {
                    guard let firstCity = route.cities.first else { continue }

                    var path = Path()
                    path.move(to: firstCity.location)
                    for city in route.cities.dropFirst() {
                        path.addLine(to: city.location)
                    }
                    path.closeSubpath()

                    // Calculate opacity: 1.0 for best, decreasing to 0.3 for 5th
                    let opacity = 1.0 - (Double(index) * 0.15)
                    context.stroke(path, with: .color(.black.opacity(opacity)), lineWidth: 1)
                }

                // Draw all-time best route as blue line (thicker, on top)
                if let allTimeBest = algorithmRunner.allTimeBestRoute,
                   let firstCity = allTimeBest.cities.first {
                    var path = Path()
                    path.move(to: firstCity.location)
                    for city in allTimeBest.cities.dropFirst() {
                        path.addLine(to: city.location)
                    }
                    path.closeSubpath()
                    context.stroke(path, with: .color(.blue), lineWidth: 2.5)
                }
            }
            .background(Color(white: 0.667))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        locations.append(value.location)
                    }
            )

            // Generation and distance labels
            VStack(spacing: 4) {
                Text(String(format: NSLocalizedString("Pathfinder.Generation", comment: ""), algorithmRunner.generation))
                    .font(.body)
                if algorithmRunner.bestDistance > 0 {
                    Text(String(format: NSLocalizedString("Pathfinder.BestDistance", comment: ""), algorithmRunner.bestDistance))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 8)

            // Control buttons
            HStack {
                Button(NSLocalizedString("Pathfinder.Button.Start", comment: "")) {
                    startAlgorithm()
                }
                .disabled(locations.count < 2 || algorithmRunner.isRunning)
                .frame(maxWidth: .infinity)

                Button(NSLocalizedString("Pathfinder.Button.Clear", comment: "")) {
                    clearAll()
                }
                .frame(maxWidth: .infinity)

                Button(NSLocalizedString("Pathfinder.Button.Stop", comment: "")) {
                    algorithmRunner.stop()
                }
                .disabled(!algorithmRunner.isRunning)
                .frame(maxWidth: .infinity)
            }
            .padding()
        }
        .onChange(of: settings.populationSize) { _ in
            resetAlgorithm()
        }
        .onChange(of: settings.mutationProbability) { _ in
            resetAlgorithm()
        }
        .onChange(of: settings.eliteSize) { _ in
            resetAlgorithm()
        }
    }

    private func startAlgorithm() {
        let cities = locations.map { City(location: $0) }
        algorithmRunner.start(with: cities, settings: settings)
    }

    private func clearAll() {
        algorithmRunner.reset()
        locations.removeAll()
    }

    private func resetAlgorithm() {
        algorithmRunner.reset()
    }
}

#Preview {
    PathfinderView()
        .environmentObject(GeneticAlgorithmSettings.shared)
}
