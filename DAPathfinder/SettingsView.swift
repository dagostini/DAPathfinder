//
//  SettingsView.swift
//  DAPathfinder
//
//  Created by Codex on 2025-02-08.
//

import Foundation
import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: GAViewModel
    @State private var populationEditing = false
    @State private var eliteEditing = false
    @State private var showPopulationError = false
    @State private var showEliteError = false

    private let populationMin = 50
    private let populationMax = 2000
    private let eliteMin = 0
    private let eliteMax = 200
    private let mutationMax = 0.05

    var body: some View {
        NavigationStack {
            Form {
                Section("section.population") {
                    populationRow
                    eliteRow
                }

                Section("section.mutation") {
                    mutationRow
                }

                Section("section.routes") {
                    Toggle(
                        String.localizedStringWithFormat(
                            NSLocalizedString("routes.showTop", comment: "Show top routes label"),
                            10
                        ),
                        isOn: showTopRoutesBinding
                    )
                }

                Section {
                    Button("action.resetDefaults") {
                        viewModel.resetSettings()
                    }
                }
            }
            .navigationTitle("settings.title")
            .onChange(of: viewModel.settings.populationSize) { newValue in
                if populationEditing {
                    return
                }
                clampPopulationSize(newValue, shouldFlash: false)
                clampEliteCount(viewModel.settings.eliteCount, shouldFlash: false)
            }
            .onChange(of: populationEditing) { isEditing in
                if !isEditing {
                    clampPopulationSize(viewModel.settings.populationSize, shouldFlash: true)
                    clampEliteCount(viewModel.settings.eliteCount, shouldFlash: false)
                }
            }
            .onChange(of: viewModel.settings.eliteCount) { newValue in
                if eliteEditing {
                    return
                }
                clampEliteCount(newValue, shouldFlash: false)
            }
            .onChange(of: eliteEditing) { isEditing in
                if !isEditing {
                    clampEliteCount(viewModel.settings.eliteCount, shouldFlash: true)
                }
            }
        }
    }

    private var showTopRoutesBinding: Binding<Bool> {
        Binding(
            get: { viewModel.showTopRoutes },
            set: { newValue in
                viewModel.showTopRoutes = newValue
            }
        )
    }

    private var populationRow: some View {
        SettingRow(
            title: NSLocalizedString("settings.populationSize", comment: "Population size title"),
            value: populationSizeBinding,
            rangeLabel: String.localizedStringWithFormat(
                NSLocalizedString("range.value", comment: "Range label"),
                populationMin,
                populationMax
            ),
            rangeIsError: showPopulationError,
            stepperRange: populationMin...populationMax,
            onEditingChanged: { populationEditing = $0 },
            showError: showPopulationError
        )
    }

    private var eliteRow: some View {
        SettingRow(
            title: NSLocalizedString("settings.eliteCount", comment: "Elite count title"),
            value: eliteCountBinding,
            rangeLabel: String.localizedStringWithFormat(
                NSLocalizedString("range.value", comment: "Range label"),
                eliteMin,
                effectiveEliteMax
            ),
            rangeIsError: showEliteError,
            stepperRange: eliteMin...effectiveEliteMax,
            onEditingChanged: { eliteEditing = $0 },
            showError: showEliteError
        )
    }

    private var mutationRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String.localizedStringWithFormat(
                NSLocalizedString("settings.mutationProbability", comment: "Mutation probability label"),
                formattedMutation
            ))
                .font(.subheadline)
            Slider(value: mutationProbabilityBinding, in: 0...mutationMax, step: 0.001)
            Text(String.localizedStringWithFormat(
                NSLocalizedString("range.zeroTo", comment: "Mutation range label"),
                formattedMutationMax
            ))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var populationSizeBinding: Binding<Int> {
        Binding(
            get: { viewModel.settings.populationSize },
            set: { newValue in
                viewModel.updateSettings { settings in
                    settings.populationSize = newValue
                }
            }
        )
    }

    private var eliteCountBinding: Binding<Int> {
        Binding(
            get: { viewModel.settings.eliteCount },
            set: { newValue in
                viewModel.updateSettings { settings in
                    settings.eliteCount = newValue
                }
            }
        )
    }

    private var mutationProbabilityBinding: Binding<Double> {
        Binding(
            get: { viewModel.settings.mutationProbability },
            set: { newValue in
                viewModel.updateSettings { settings in
                    settings.mutationProbability = min(newValue, mutationMax)
                }
            }
        )
    }

    private var formattedMutation: String {
        let percentage = viewModel.settings.mutationProbability * 100
        return String(format: "%.1f%%", percentage)
    }

    private var formattedMutationMax: String {
        String(format: "%.1f%%", mutationMax * 100)
    }

    private var effectiveEliteMax: Int {
        min(eliteMax, viewModel.settings.populationSize)
    }

    private func clampPopulationSize(_ value: Int, shouldFlash: Bool) {
        let clamped = min(max(value, populationMin), populationMax)
        if clamped != value {
            viewModel.updateSettings { settings in
                settings.populationSize = clamped
            }
            if shouldFlash {
                flashPopulationError()
            }
        }
    }

    private func clampEliteCount(_ value: Int, shouldFlash: Bool) {
        let clamped = min(max(value, eliteMin), effectiveEliteMax)
        if clamped != value {
            viewModel.updateSettings { settings in
                settings.eliteCount = clamped
            }
            if shouldFlash {
                flashEliteError()
            }
        }
    }

    private func flashPopulationError() {
        showPopulationError = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 600_000_000)
            showPopulationError = false
        }
    }

    private func flashEliteError() {
        showEliteError = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 600_000_000)
            showEliteError = false
        }
    }
}

private struct SettingRow: View {
    let title: String
    let value: Binding<Int>
    let rangeLabel: String
    let rangeIsError: Bool
    let stepperRange: ClosedRange<Int>
    let onEditingChanged: (Bool) -> Void
    let showError: Bool
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
            HStack {
                TextField(
                    "",
                    value: value,
                    format: .number
                )
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)
                .focused($isFocused)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button(NSLocalizedString("action.done", comment: "Keyboard done button")) {
                            isFocused = false
                        }
                    }
                }
                .onChange(of: isFocused) { newValue in
                    onEditingChanged(newValue)
                }

                Stepper("", value: value, in: stepperRange)
                    .labelsHidden()
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(showError ? Color.red : Color.clear, lineWidth: 2)
            )

            Text(rangeLabel)
                .font(.caption)
                .foregroundColor(rangeIsError ? .red : .secondary)
        }
    }
}

#Preview {
    SettingsView(viewModel: GAViewModel())
}
