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
                    FilterSection(title: L("filters.primary.metabolism")) {
                        chipGrid {
                            FilterChip(title: L("filters.all"), systemImage: nil, isSelected: filterPrimaryMetabolism == nil) {
                                filterPrimaryMetabolism = nil
                            }
                            ForEach(PrimaryMetabolism.allCases, id: \.self) { metabolism in
                                FilterChip(title: metabolism.rawValue, systemImage: metabolism.icon, tint: metabolism.color, isSelected: filterPrimaryMetabolism == metabolism) {
                                    filterPrimaryMetabolism = metabolism
                                }
                            }
                        }
                    }

                    FilterSection(title: L("filters.biomechanical.structure")) {
                        chipGrid {
                            FilterChip(title: L("filters.all"), systemImage: nil, isSelected: filterBiomechanicalStructure == nil) {
                                filterBiomechanicalStructure = nil
                            }
                            ForEach(BiomechanicalStructure.allCases, id: \.self) { structure in
                                FilterChip(title: structure.rawValue, systemImage: structure.icon, isSelected: filterBiomechanicalStructure == structure) {
                                    filterBiomechanicalStructure = structure
                                }
                            }
                        }
                    }

                    FilterSection(title: L("filters.training.role")) {
                        chipGrid {
                            FilterChip(title: L("filters.all"), systemImage: nil, isSelected: filterTrainingRole == nil) {
                                filterTrainingRole = nil
                            }
                            ForEach(TrainingRole.allCases, id: \.self) { role in
                                FilterChip(title: role.rawValue, systemImage: role.icon, tint: role.color, isSelected: filterTrainingRole == role) {
                                    filterTrainingRole = role
                                }
                            }
                        }
                    }

                    FilterSection(title: L("filters.category")) {
                        chipGrid {
                            FilterChip(title: L("filters.all"), systemImage: nil, isSelected: filterCategory == nil) {
                                filterCategory = nil
                            }
                            ForEach(ExerciseCategory.allCases, id: \.self) { category in
                                FilterChip(title: category.rawValue, systemImage: category.icon, tint: category.color, isSelected: filterCategory == category) {
                                    filterCategory = category
                                }
                            }
                        }
                    }

                    FilterSection(title: L("filters.reference.plane")) {
                        chipGrid {
                            FilterChip(title: L("filters.all"), systemImage: nil, isSelected: filterReferencePlane == nil) {
                                filterReferencePlane = nil
                            }
                            ForEach(ReferencePlane.allCases, id: \.self) { plane in
                                FilterChip(title: plane.rawValue, systemImage: plane.icon, tint: plane.color, isSelected: filterReferencePlane == plane) {
                                    filterReferencePlane = plane
                                }
                            }
                        }
                    }

                    FilterSection(title: L("filters.motor.schemas")) {
                        chipGrid {
                            FilterChip(title: L("filters.all"), systemImage: nil, isSelected: filterMotorSchemas.isEmpty) {
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

                    FilterSection(title: L("filters.tags")) {
                        chipGrid {
                            FilterChip(title: L("filters.all"), systemImage: nil, isSelected: filterTags.isEmpty) {
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

                    FilterSection(title: L("filters.primary.muscle")) {
                        VStack(alignment: .leading, spacing: 12) {
                            GlassSearchField(text: $muscleSearchText, placeholder: L("muscles.search"))

                            Button(action: { filterPrimaryMuscle = nil }) {
                                Label(L("muscles.all"), systemImage: filterPrimaryMuscle == nil ? "checkmark.circle.fill" : "figure.strengthtraining.traditional")
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

                    FilterSection(title: L("filters.favorites")) {
                        Toggle(L("filters.favorites.only"), isOn: $filterFavoritesOnly)
                            .toggleStyle(SwitchToggleStyle(tint: .yellow))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 32)
            }
            .navigationTitle(L("exercises.filters.title"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("common.close")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("common.reset")) { onClearAll() }
                }
            }
        }
        .appScreenBackground()
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
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.subtleText(for: colorScheme))
                .tracking(0.6)
            content()
        }
        .dashboardCardStyle()
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

private struct GlassSearchField: View {
    @Binding var text: String
    let placeholder: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppTheme.subtleText(for: colorScheme))
            TextField(placeholder, text: $text)
                .textInputAutocapitalization(.words)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.cardBackground(for: colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(AppTheme.stroke(for: colorScheme), lineWidth: 1)
                )
        )
    }
}
