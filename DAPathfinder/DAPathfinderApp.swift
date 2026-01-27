//
//  DAPathfinderApp.swift
//  DAPathfinder
//
//  Created by Codex on 2025-02-08.
//

import SwiftUI

@main
struct DAPathfinderApp: App {
    @StateObject private var viewModel = GAViewModel()

    var body: some Scene {
        WindowGroup {
            MainTabView(viewModel: viewModel)
        }
    }
}
