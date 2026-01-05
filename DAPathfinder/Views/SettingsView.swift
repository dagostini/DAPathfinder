//
//  SettingsView.swift
//  DAPathfinder
//
//  Created by Claude on 2026-01-05.
//  Copyright © 2026 agostini.tech. All rights reserved.
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

    // Real-time validation
    private var isPopulationSizeValid: Bool {
        guard let value = Int(populationSizeText) else { return false }
        return (10...2000).contains(value)
    }

    private var isMutationProbabilityValid: Bool {
        guard let value = Double(mutationProbabilityText) else { return false }
        return (0.001...0.5).contains(value)
    }

    private var isEliteSizeValid: Bool {
        guard let value = Int(eliteSizeText) else { return false }
        guard let popSize = Int(populationSizeText) else { return false }
        return (1...50).contains(value) && value < popSize
    }

    private var allFieldsValid: Bool {
        isPopulationSizeValid && isMutationProbabilityValid && isEliteSizeValid
    }

    var body: some View {
        VStack(spacing: 20) {
            Text(NSLocalizedString("Settings.Title", comment: ""))
                .font(.title)
                .fontWeight(.bold)
                .padding(.top)

            // Population Size
            VStack(alignment: .leading, spacing: 8) {
                Text(NSLocalizedString("Settings.PopulationSize.Label", comment: ""))
                    .font(.headline)
                TextField(NSLocalizedString("Settings.PopulationSize.Placeholder", comment: ""), text: $populationSizeText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(populationSizeText.isEmpty ? Color.clear : (isPopulationSizeValid ? Color.green : Color.red), lineWidth: 1)
                    )
                Text(NSLocalizedString("Settings.PopulationSize.Range", comment: ""))
                    .font(.caption)
                    .foregroundColor(populationSizeText.isEmpty || isPopulationSizeValid ? .gray : .red)
            }
            .padding(.horizontal)

            // Mutation Probability
            VStack(alignment: .leading, spacing: 8) {
                Text(NSLocalizedString("Settings.MutationProbability.Label", comment: ""))
                    .font(.headline)
                TextField(NSLocalizedString("Settings.MutationProbability.Placeholder", comment: ""), text: $mutationProbabilityText)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(mutationProbabilityText.isEmpty ? Color.clear : (isMutationProbabilityValid ? Color.green : Color.red), lineWidth: 1)
                    )
                Text(NSLocalizedString("Settings.MutationProbability.Range", comment: ""))
                    .font(.caption)
                    .foregroundColor(mutationProbabilityText.isEmpty || isMutationProbabilityValid ? .gray : .red)
            }
            .padding(.horizontal)

            // Elite Size
            VStack(alignment: .leading, spacing: 8) {
                Text(NSLocalizedString("Settings.EliteSize.Label", comment: ""))
                    .font(.headline)
                TextField(NSLocalizedString("Settings.EliteSize.Placeholder", comment: ""), text: $eliteSizeText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(eliteSizeText.isEmpty ? Color.clear : (isEliteSizeValid ? Color.green : Color.red), lineWidth: 1)
                    )
                Text(NSLocalizedString("Settings.EliteSize.Range", comment: ""))
                    .font(.caption)
                    .foregroundColor(eliteSizeText.isEmpty || isEliteSizeValid ? .gray : .red)
            }
            .padding(.horizontal)

            Spacer()

            // Update Button
            Button(action: updateSettings) {
                Text(NSLocalizedString("Settings.Button.Update", comment: ""))
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(allFieldsValid ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(!allFieldsValid)
            .padding(.horizontal)

            // Reset Button
            Button(action: resetSettings) {
                Text(NSLocalizedString("Settings.Button.Reset", comment: ""))
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
        .alert(NSLocalizedString("Alert.Error.Title", comment: ""), isPresented: $showError) {
            Button(NSLocalizedString("Alert.Button.OK", comment: ""), role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert(NSLocalizedString("Alert.Success.Title", comment: ""), isPresented: $showSuccess) {
            Button(NSLocalizedString("Alert.Button.OK", comment: ""), role: .cancel) {}
        } message: {
            Text(NSLocalizedString("Alert.Settings.Success", comment: ""))
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
            errorMessage = NSLocalizedString("Alert.Settings.InvalidValues", comment: "")
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
            errorMessage = NSLocalizedString("Alert.Settings.GenericError", comment: "")
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
