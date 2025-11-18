import SwiftUI
import SwiftData

struct ExerciseFiltersView: View {
    @Binding var filterPrimaryMetabolism: PrimaryMetabolism?
    @Binding var filterBiomechanicalStructure: BiomechanicalStructure?
    @Binding var filterTrainingRole: TrainingRole?
    @Binding var filterCategory: ExerciseCategory?
    @Binding var filterPrimaryMuscle: Muscle?
    @Binding var filterReferencePlane: ReferencePlane?
    @Binding var filterMotorSchemas: Set<MotorSchema>
    @Binding var filterTags: Set<ExerciseTag>
    @Binding var filterFavoritesOnly: Bool

    let muscles: [Muscle]
    let onClearAll: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var muscleSearchText = ""

    private let chipColumns = [GridItem(.adaptive(minimum: 140), spacing: 8)]

    private var filteredMuscles: [Muscle] {
        guard !muscleSearchText.isEmpty else { return muscles }
        return muscles.filter { $0.name.localizedCaseInsensitiveContains(muscleSearchText) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    FilterSection(title: "Metabolismo primario") {
                        chipGrid {
                            FilterChip(title: "Tutti", systemImage: nil, isSelected: filterPrimaryMetabolism == nil) {
                                filterPrimaryMetabolism = nil
                            }
                            ForEach(PrimaryMetabolism.allCases, id: \.self) { metabolism in
                                FilterChip(title: metabolism.rawValue, systemImage: metabolism.icon, tint: metabolism.color, isSelected: filterPrimaryMetabolism == metabolism) {
                                    filterPrimaryMetabolism = metabolism
                                }
                            }
                        }
                    }

                    FilterSection(title: "Struttura biomeccanica") {
                        chipGrid {
                            FilterChip(title: "Tutte", systemImage: nil, isSelected: filterBiomechanicalStructure == nil) {
                                filterBiomechanicalStructure = nil
                            }
                            ForEach(BiomechanicalStructure.allCases, id: \.self) { structure in
                                FilterChip(title: structure.rawValue, systemImage: structure.icon, isSelected: filterBiomechanicalStructure == structure) {
                                    filterBiomechanicalStructure = structure
                                }
                            }
                        }
                    }

                    FilterSection(title: "Ruolo nell'allenamento") {
                        chipGrid {
                            FilterChip(title: "Tutti", systemImage: nil, isSelected: filterTrainingRole == nil) {
                                filterTrainingRole = nil
                            }
                            ForEach(TrainingRole.allCases, id: \.self) { role in
                                FilterChip(title: role.rawValue, systemImage: role.icon, tint: role.color, isSelected: filterTrainingRole == role) {
                                    filterTrainingRole = role
                                }
                            }
                        }
                    }

                    FilterSection(title: "Categoria") {
                        chipGrid {
                            FilterChip(title: "Tutte", systemImage: nil, isSelected: filterCategory == nil) {
                                filterCategory = nil
                            }
                            ForEach(ExerciseCategory.allCases, id: \.self) { category in
                                FilterChip(title: category.rawValue, systemImage: category.icon, tint: category.color, isSelected: filterCategory == category) {
                                    filterCategory = category
                                }
                            }
                        }
                    }

                    FilterSection(title: "Piano di riferimento") {
                        chipGrid {
                            FilterChip(title: "Tutti", systemImage: nil, isSelected: filterReferencePlane == nil) {
                                filterReferencePlane = nil
                            }
                            ForEach(ReferencePlane.allCases, id: \.self) { plane in
                                FilterChip(title: plane.rawValue, systemImage: plane.icon, tint: plane.color, isSelected: filterReferencePlane == plane) {
                                    filterReferencePlane = plane
                                }
                            }
                        }
                    }

                    FilterSection(title: "Schemi motori") {
                        chipGrid {
                            FilterChip(title: "Tutti", systemImage: nil, isSelected: filterMotorSchemas.isEmpty) {
                                filterMotorSchemas.removeAll()
                            }
                            ForEach(MotorSchema.allCases) { schema in
                                FilterChip(title: schema.rawValue, systemImage: schema.icon, tint: schema.color, isSelected: filterMotorSchemas.contains(schema)) {
                                    if filterMotorSchemas.contains(schema) {
                                        filterMotorSchemas.remove(schema)
                                    } else {
                                        filterMotorSchemas.insert(schema)
                                    }
                                }
                            }
                        }
                        .accessibilityElement(children: .contain)
                    }

                    FilterSection(title: "Tag") {
                        chipGrid {
                            FilterChip(title: "Tutti", systemImage: nil, isSelected: filterTags.isEmpty) {
                                filterTags.removeAll()
                            }
                            ForEach(ExerciseTag.allCases) { tag in
                                FilterChip(title: tag.rawValue, systemImage: tag.icon, tint: tag.color, isSelected: filterTags.contains(tag)) {
                                    if filterTags.contains(tag) {
                                        filterTags.remove(tag)
                                    } else {
                                        filterTags.insert(tag)
                                    }
                                }
                            }
                        }
                    }

                    FilterSection(title: "Muscolo primario") {
                        VStack(alignment: .leading, spacing: 12) {
                            TextField("Cerca muscolo", text: $muscleSearchText)
                                .textFieldStyle(.roundedBorder)

                            Button(action: { filterPrimaryMuscle = nil }) {
                                Label("Tutti i muscoli", systemImage: filterPrimaryMuscle == nil ? "checkmark.circle.fill" : "figure.strengthtraining.traditional")
                                    .labelStyle(.titleAndIcon)
                            }
                            .buttonStyle(.bordered)

                            LazyVStack(alignment: .leading, spacing: 8) {
                                ForEach(filteredMuscles) { muscle in
                                    Button {
                                        filterPrimaryMuscle = muscle
                                    } label: {
                                        HStack {
                                            Image(systemName: filterPrimaryMuscle?.id == muscle.id ? "checkmark.circle.fill" : "circle")
                                            Text(muscle.name)
                                                .lineLimit(1)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    FilterSection(title: "Preferiti") {
                        Toggle("Mostra solo preferiti", isOn: $filterFavoritesOnly)
                            .toggleStyle(SwitchToggleStyle(tint: .yellow))
                    }
                }
                .padding(.horizontal)
                .padding(.top, 24)
                .padding(.bottom, 32)
            }
            .navigationTitle("Filtri esercizi")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Chiudi") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Reset") { onClearAll() }
                }
            }
        }
    }

    @ViewBuilder
    private func chipGrid<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        LazyVGrid(columns: chipColumns, spacing: 8) {
            content()
        }
    }
}

struct FilterSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.caption)
                .foregroundStyle(.secondary)
            content()
        }
    }
}

struct FilterChip: View {
    let title: String
    var systemImage: String?
    var tint: Color = .accentColor
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
                    .lineLimit(1)
                if isSelected {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption2)
                }
            }
            .font(.footnote)
            .foregroundStyle(isSelected ? .white : tint)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(
                Capsule()
                    .fill(isSelected ? tint : tint.opacity(0.15))
            )
        }
        .buttonStyle(.plain)
    }
}
