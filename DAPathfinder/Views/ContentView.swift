//
//  ContentView.swift
//  DAPathfinder
//
//  Created by Claude on 2026-01-05.
//  Copyright © 2026 Domenico. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var settings: GeneticAlgorithmSettings

    var body: some View {
        TabView {
            PathfinderView()
                .tabItem {
                    Label("Pathfinder", systemImage: "map")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(GeneticAlgorithmSettings.shared)
}
