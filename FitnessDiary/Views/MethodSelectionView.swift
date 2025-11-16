import SwiftUI

struct MethodSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    let onSelect: (MethodType) -> Void

    var body: some View {
        NavigationStack {
            List {
                Section("Serie Multiple") {
                    ForEach([MethodType.superset, .triset, .giantSet], id: \.self) { method in
                        MethodRow(method: method) {
                            onSelect(method)
                            dismiss()
                        }
                    }
                }

                Section("Intensità e Volume") {
                    ForEach([MethodType.dropset, .pyramidAscending, .pyramidDescending], id: \.self) { method in
                        MethodRow(method: method) {
                            onSelect(method)
                            dismiss()
                        }
                    }
                }

                Section("Potenza e Forza") {
                    ForEach([MethodType.contrastTraining, .complexTraining], id: \.self) { method in
                        MethodRow(method: method) {
                            onSelect(method)
                            dismiss()
                        }
                    }
                }

                Section("Densità e Timing") {
                    ForEach([MethodType.rest_pause, .cluster, .emom], id: \.self) { method in
                        MethodRow(method: method) {
                            onSelect(method)
                            dismiss()
                        }
                    }
                }

                Section("Condizionamento") {
                    ForEach([MethodType.amrap, .circuit], id: \.self) { method in
                        MethodRow(method: method) {
                            onSelect(method)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("Seleziona Metodo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") {
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
                            Text("\(method.minExercises)+ es.")
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
