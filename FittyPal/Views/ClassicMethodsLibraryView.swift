//
//  ClassicMethodsLibraryView.swift
//  FittyPal
//
//  Created by Claude on 20/11/2025.
//

import SwiftUI

struct ClassicMethodsLibraryView: View {
    @Environment(\.colorScheme) private var colorScheme

    // Only rep-based methods (excluding duration-based: EMOM, AMRAP, Circuit, Tabata)
    private let repBasedMethods: [MethodType] = [
        .superset,
        .triset,
        .giantSet,
        .dropset,
        .pyramidAscending,
        .pyramidDescending,
        .contrastTraining,
        .complexTraining,
        .rest_pause,
        .cluster
    ]

    // Group methods by category
    private var methodsByCategory: [(String, [MethodType])] {
        [
            ("Multi-Set", [.superset, .triset, .giantSet]),
            ("Intensità & Volume", [.dropset, .pyramidAscending, .pyramidDescending]),
            ("Potenza & Forza", [.contrastTraining, .complexTraining]),
            ("Densità & Timing", [.rest_pause, .cluster])
        ]
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Libreria Metodi Classici")
                        .font(.title2.bold())
                    Text("Esplora i metodi di allenamento basati su ripetizioni con descrizioni dettagliate ed esempi pratici.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 8)

                // Methods grouped by category
                ForEach(methodsByCategory, id: \.0) { category, methods in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(category.uppercased())
                            .font(.caption.weight(.semibold))
                            .tracking(0.6)
                            .foregroundStyle(AppTheme.subtleText(for: colorScheme))
                            .padding(.horizontal, 20)

                        VStack(spacing: 12) {
                            ForEach(methods, id: \.self) { method in
                                NavigationLink {
                                    ClassicMethodDetailView(method: method)
                                } label: {
                                    ClassicMethodCard(method: method)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .padding(.vertical, 24)
        }
        .navigationTitle("Metodi Classici")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Classic Method Card

private struct ClassicMethodCard: View {
    let method: MethodType
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(method.color.opacity(0.15))
                .frame(width: 52, height: 52)
                .overlay(
                    Image(systemName: method.icon)
                        .font(.title3)
                        .foregroundStyle(method.color)
                )

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(method.rawValue)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(method.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(AppTheme.subtleText(for: colorScheme))
        }
        .padding(16)
        .background(AppTheme.cardBackground(for: colorScheme))
        .cornerRadius(16)
    }
}

#Preview {
    NavigationStack {
        ClassicMethodsLibraryView()
    }
}
