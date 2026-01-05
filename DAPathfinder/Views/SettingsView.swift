//
//  SettingsView.swift
//  DAPathfinder
//
//  Created by Claude on 2026-01-05.
//  Copyright © 2026 Domenico. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: GeneticAlgorithmSettings

    @State private var populationSizeText: String = ""
    @State private var mutationProbabilityText: String = ""
    @State private var eliteSizeText: String = ""

    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var showSuccess: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Algorithm Settings")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top)

            // Population Size
            VStack(alignment: .leading, spacing: 8) {
                Text("Population Size")
                    .font(.headline)
                TextField("Population Size", text: $populationSizeText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                Text("Range: 10 - 2000")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)

            // Mutation Probability
            VStack(alignment: .leading, spacing: 8) {
                Text("Mutation Probability")
                    .font(.headline)
                TextField("Mutation Probability", text: $mutationProbabilityText)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                Text("Range: 0.001 - 0.5")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)

            // Elite Size
            VStack(alignment: .leading, spacing: 8) {
                Text("Elite Size")
                    .font(.headline)
                TextField("Elite Size", text: $eliteSizeText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                Text("Range: 1 - 50")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)

            Spacer()

            // Update Button
            Button(action: updateSettings) {
                Text("Update")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)

            // Reset Button
            Button(action: resetSettings) {
                Text("Reset to Defaults")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.clear)
                    .foregroundColor(.blue)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.blue, lineWidth: 2)
                    )
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .onAppear {
            loadSettings()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("Success", isPresented: $showSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Settings updated successfully")
        }
    }

    private func loadSettings() {
        populationSizeText = "\(settings.populationSize)"
        mutationProbabilityText = "\(settings.mutationProbability)"
        eliteSizeText = "\(settings.eliteSize)"
    }

    private func updateSettings() {
        guard let populationSize = Int(populationSizeText),
              let mutationProbability = Double(mutationProbabilityText),
              let eliteSize = Int(eliteSizeText) else {
            errorMessage = "Please enter valid numeric values"
            showError = true
            return
        }

        do {
            try settings.updateSettings(
                populationSize: populationSize,
                mutationProbability: mutationProbability,
                eliteSize: eliteSize
            )
            showSuccess = true
        } catch let error as GeneticAlgorithmSettings.ValidationError {
            errorMessage = error.localizedDescription
            showError = true
        } catch {
            errorMessage = "An error occurred while updating settings"
            showError = true
        }
    }

    private func resetSettings() {
        settings.resetToDefaults()
        loadSettings()
        showSuccess = true
    }
}

#Preview {
    SettingsView()
        .environmentObject(GeneticAlgorithmSettings.shared)
}
