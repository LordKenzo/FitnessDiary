//
//  CustomMethodSelectionView.swift
//  FittyPal
//
//  Created by Claude on 20/11/2025.
//

import SwiftUI
import SwiftData

struct CustomMethodSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \CustomTrainingMethod.name) private var customMethods: [CustomTrainingMethod]

    let onSelect: (CustomTrainingMethod) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if customMethods.isEmpty {
                        GlassEmptyStateCard(
                            systemImage: "bolt.circle.fill",
                            title: "Nessun Metodo Custom",
                            description: "Crea il tuo primo metodo di allenamento personalizzato dalle impostazioni."
                        )
                        .padding(.horizontal, 20)
                        .padding(.vertical, 24)
                    } else {
                        ForEach(customMethods) { method in
                            Button {
                                onSelect(method)
                                dismiss()
                            } label: {
                                CustomMethodCard(method: method)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.vertical, 16)
            }
            .navigationTitle("Seleziona Metodo Custom")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") {
                        dismiss()
                    }
                }
            }
        }
        .appScreenBackground()
    }
}

struct CustomMethodCard: View {
    let method: CustomTrainingMethod

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bolt.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)

                VStack(alignment: .leading, spacing: 4) {
                    Text(method.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(method.methodDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Preview of configurations
            if !method.repConfigurations.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(method.repConfigurations.sorted(by: { $0.repOrder < $1.repOrder })) { config in
                            VStack(spacing: 4) {
                                Text("Rep \(config.repOrder)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)

                                Text(config.formattedLoadPercentage)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.accentColor)

                                if config.restAfterRep > 0 {
                                    Text(config.formattedRestTime)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(Color.accentColor.opacity(0.1))
                            .cornerRadius(6)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.accentColor.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container: ModelContainer
    do {
        container = try ModelContainer(for: CustomTrainingMethod.self, configurations: config)
    } catch {
        fatalError("Failed to create ModelContainer for preview: \(error)")
    }

    // Create sample methods
    let method1 = CustomTrainingMethod(
        name: "Metodo Variabile",
        repConfigurations: [
            CustomRepConfiguration(repOrder: 1, loadPercentage: 0, restAfterRep: 0),
            CustomRepConfiguration(repOrder: 2, loadPercentage: 5, restAfterRep: 10),
            CustomRepConfiguration(repOrder: 3, loadPercentage: 5, restAfterRep: 10),
            CustomRepConfiguration(repOrder: 4, loadPercentage: -15, restAfterRep: 15),
            CustomRepConfiguration(repOrder: 5, loadPercentage: -15, restAfterRep: 15),
            CustomRepConfiguration(repOrder: 6, loadPercentage: 30, restAfterRep: 20),
        ]
    )

    let method2 = CustomTrainingMethod(
        name: "Progressivo",
        repConfigurations: [
            CustomRepConfiguration(repOrder: 1, loadPercentage: 0, restAfterRep: 5),
            CustomRepConfiguration(repOrder: 2, loadPercentage: 10, restAfterRep: 10),
            CustomRepConfiguration(repOrder: 3, loadPercentage: 20, restAfterRep: 15),
        ]
    )

    container.mainContext.insert(method1)
    container.mainContext.insert(method2)

    return CustomMethodSelectionView { method in
        print("Selected: \(method.name)")
    }
    .modelContainer(container)
}
