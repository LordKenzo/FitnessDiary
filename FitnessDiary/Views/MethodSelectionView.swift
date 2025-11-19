import SwiftUI

struct MethodSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    let onSelect: (MethodType) -> Void

    var body: some View {
        NavigationStack {
            List {
                Section(L("methods.section.multi.sets")) {
                    ForEach([MethodType.superset, .triset, .giantSet], id: \.self) { method in
                        MethodRow(method: method) {
                            onSelect(method)
                            dismiss()
                        }
                    }
                }

                Section(L("methods.section.intensity.volume")) {
                    ForEach([MethodType.dropset, .pyramidAscending, .pyramidDescending], id: \.self) { method in
                        MethodRow(method: method) {
                            onSelect(method)
                            dismiss()
                        }
                    }
                }

                Section(L("methods.section.power.strength")) {
                    ForEach([MethodType.contrastTraining, .complexTraining], id: \.self) { method in
                        MethodRow(method: method) {
                            onSelect(method)
                            dismiss()
                        }
                    }
                }

                Section(L("methods.section.density.timing")) {
                    ForEach([MethodType.rest_pause, .cluster, .emom], id: \.self) { method in
                        MethodRow(method: method) {
                            onSelect(method)
                            dismiss()
                        }
                    }
                }

                Section(L("methods.section.conditioning")) {
                    ForEach([MethodType.amrap, .circuit, .tabata], id: \.self) { method in
                        MethodRow(method: method) {
                            onSelect(method)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(L("methods.select"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("common.cancel")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct MethodRow: View {
    let method: MethodType
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: method.icon)
                    .font(.title2)
                    .foregroundStyle(method.color)
                    .frame(width: 40)

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(method.rawValue)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Spacer()

                        // Min exercises badge
                        if method.minExercises > 1 {
                            Text(String(format: L("methods.min.exercises.badge"), method.minExercises))
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(method.color.opacity(0.2))
                                .foregroundStyle(method.color)
                                .clipShape(Capsule())
                        }
                    }

                    Text(method.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

#Preview {
    MethodSelectionView { method in
        print("Selected: \(method.rawValue)")
    }
}
