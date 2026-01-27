//
//  ContentView.swift
//  DAPathfinder
//
//  Created by Codex on 2025-02-08.
//

import Foundation
import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: GAViewModel

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(String.localizedStringWithFormat(
                    NSLocalizedString("status.generation", comment: "Generation label"),
                    viewModel.generation
                ))
                    .font(.headline)
                Spacer()
                Text(String.localizedStringWithFormat(
                    NSLocalizedString("status.cities", comment: "Cities label"),
                    viewModel.locations.count
                ))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Text(shortestDistanceLabel)
                .font(.subheadline)
                .foregroundColor(.secondary)

            GeometryReader { proxy in
                ZStack {
                    Color(.secondarySystemBackground)
                    Canvas { context, size in
                        drawCities(in: &context)
                        drawRoutes(in: &context)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color(.separator), lineWidth: 1)
                )
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onEnded { value in
                            viewModel.addLocation(value.location)
                        }
                )
            }

            HStack(spacing: 12) {
                Button("action.start") {
                    viewModel.startEvolution()
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.locations.count < 2 || viewModel.isEvolving)

                Button("action.stop") {
                    viewModel.stopEvolution()
                }
                .buttonStyle(.bordered)
                .disabled(!viewModel.isEvolving)

                Button("action.clear") {
                    viewModel.clear()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .onDisappear {
            viewModel.stopEvolution()
        }
    }

    private func drawCities(in context: inout GraphicsContext) {
        for point in viewModel.locations {
            let rect = CGRect(x: point.x - 4, y: point.y - 4, width: 8, height: 8)
            context.fill(Path(ellipseIn: rect), with: .color(.red))
        }
    }

    private var shortestDistanceLabel: String {
        guard let shortestDistance = viewModel.shortestDistance else {
            return NSLocalizedString("status.shortest.placeholder", comment: "Shortest placeholder")
        }
        return String.localizedStringWithFormat(
            NSLocalizedString("status.shortest.value", comment: "Shortest distance label"),
            Double(shortestDistance)
        )
    }

    private func drawRoutes(in context: inout GraphicsContext) {
        if viewModel.showTopRoutes {
            for route in viewModel.nextBestRoutes.prefix(10) {
                stroke(route: route, in: &context, color: .gray, lineWidth: 0.8)
            }
        }

        if let bestRoute = viewModel.bestRoute {
            stroke(route: bestRoute, in: &context, color: .black, lineWidth: 2)
        }
    }

    private func stroke(
        route: Route,
        in context: inout GraphicsContext,
        color: Color,
        lineWidth: CGFloat
    ) {
        guard let first = route.cities.first else { return }
        var path = Path()
        path.move(to: first.location)
        for city in route.cities.dropFirst() {
            path.addLine(to: city.location)
        }
        path.addLine(to: first.location)
        context.stroke(path, with: .color(color), lineWidth: lineWidth)
    }
}

#Preview {
    ContentView(viewModel: GAViewModel())
}
