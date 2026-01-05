//
//  ContentView.swift
//  DAPathfinder
//
//  Created by Claude on 2026-01-05.
//  Copyright © 2026 agostini.tech. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var settings: GeneticAlgorithmSettings

    var body: some View {
        TabView {
            PathfinderView()
                .tabItem {
                    Label(NSLocalizedString("Tab.Pathfinder", comment: ""), systemImage: "map")
                }

            SettingsView()
                .tabItem {
                    Label(NSLocalizedString("Tab.Settings", comment: ""), systemImage: "gear")
                }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(GeneticAlgorithmSettings.shared)
}
