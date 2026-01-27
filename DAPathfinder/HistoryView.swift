//
//  HistoryView.swift
//  DAPathfinder
//
//  Created by Codex on 2026-01-27.
//

import SwiftUI

struct HistoryView: View {
    @ObservedObject var viewModel: GAViewModel
    let onSelectEntry: (HistoryEntry) -> Void

    var body: some View {
        NavigationStack {
            if viewModel.history.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary)
                    Text("history.empty")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGroupedBackground))
                .navigationTitle("history.title")
            } else {
                List {
                    ForEach(viewModel.history) { entry in
                        Button {
                            onSelectEntry(entry)
                        } label: {
                            HistoryRow(entry: entry)
                        }
                    }
                    .onDelete(perform: viewModel.deleteHistory)
                }
                .navigationTitle("history.title")
                .toolbar {
                    Button("action.clearHistory") {
                        viewModel.clearHistory()
                    }
                }
            }
        }
    }
}

private struct HistoryRow: View {
    let entry: HistoryEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(Self.dateFormatter.string(from: entry.createdAt))
                .font(.headline)
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var subtitle: String {
        let bestDistance = entry.shortestDistance.map { String(format: "%.2f", $0) } ?? "--"
        return String.localizedStringWithFormat(
            NSLocalizedString("history.item.subtitle", comment: "History row subtitle"),
            entry.cities.count,
            bestDistance,
            entry.generation
        )
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

#Preview {
    HistoryView(viewModel: GAViewModel(), onSelectEntry: { _ in })
}
