//
//  MainTabView.swift
//  DAPathfinder
//
//  Created by Codex on 2025-02-08.
//

import SwiftUI

struct MainTabView: View {
    @ObservedObject var viewModel: GAViewModel

    var body: some View {
        TabView {
            ContentView(viewModel: viewModel)
                .tabItem {
                    Label("tab.pathfinder", systemImage: "map")
                }

            SettingsView(viewModel: viewModel)
                .tabItem {
                    Label("tab.settings", systemImage: "slider.horizontal.3")
                }
        }
    }
}

#Preview {
    MainTabView(viewModel: GAViewModel())
}
