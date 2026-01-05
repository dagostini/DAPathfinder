//
//  PathfinderView.swift
//  DAPathfinder
//
//  Created by Claude on 2026-01-05.
//  Copyright © 2026 Domenico. All rights reserved.
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

                // Draw route as black line
                if let route = algorithmRunner.currentRoute, !route.cities.isEmpty {
                    var path = Path()
                    path.move(to: route.cities.first!.location)
                    for city in route.cities.dropFirst() {
                        path.addLine(to: city.location)
                    }
                    path.closeSubpath()
                    context.stroke(path, with: .color(.black), lineWidth: 1)
                }
            }
            .background(Color(white: 0.667))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        locations.append(value.location)
                    }
            )

            // Generation label
            Text("Generation: \(algorithmRunner.generation)")
                .padding(.vertical, 8)

            // Control buttons
            HStack {
                Button("Start") {
                    startAlgorithm()
                }
                .disabled(locations.count < 2 || algorithmRunner.isRunning)
                .frame(maxWidth: .infinity)

                Button("Clear") {
                    clearAll()
                }
                .frame(maxWidth: .infinity)

                Button("Stop") {
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
