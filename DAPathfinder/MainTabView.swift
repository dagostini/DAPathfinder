//
//  MainTabView.swift
//  DAPathfinder
//
//  Created by Codex on 2025-02-08.
//

import SwiftUI

struct MainTabView: View {
    @ObservedObject var viewModel: GAViewModel
    @State private var selectedTab: Tab = .pathfinder

    private enum Tab: Hashable {
        case pathfinder
        case settings
        case history
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            ContentView(viewModel: viewModel)
                .tabItem {
                    Label("tab.pathfinder", systemImage: "map")
                }
                .tag(Tab.pathfinder)

            HistoryView(viewModel: viewModel) { entry in
                viewModel.loadHistory(entry)
                selectedTab = .pathfinder
            }
                .tabItem {
                    Label("tab.history", systemImage: "clock.arrow.circlepath")
                }
                .tag(Tab.history)

            SettingsView(viewModel: viewModel)
                .tabItem {
                    Label("tab.settings", systemImage: "slider.horizontal.3")
                }
                .tag(Tab.settings)
        }
    }
}

#Preview {
    MainTabView(viewModel: GAViewModel())
}
