import SwiftUI

struct ExerciseFiltersSummaryBar: View {
    @Binding var filterPrimaryMuscle: Muscle?
    @Binding var filterPrimaryMetabolism: PrimaryMetabolism?
    @Binding var filterBiomechanicalStructure: BiomechanicalStructure?
    @Binding var filterTrainingRole: TrainingRole?
    @Binding var filterCategory: ExerciseCategory?
    @Binding var filterReferencePlane: ReferencePlane?
    @Binding var filterMotorSchemas: Set<MotorSchema>
    @Binding var filterTags: Set<ExerciseTag>
    @Binding var filterFavoritesOnly: Bool
    let onClearAll: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if let muscle = filterPrimaryMuscle {
                    ExerciseFilterChip(title: muscle.name, systemImage: "figure.strengthtraining.traditional") {
                        filterPrimaryMuscle = nil
                    }
                }

                if let metabolism = filterPrimaryMetabolism {
                    ExerciseFilterChip(title: metabolism.rawValue, systemImage: metabolism.icon) {
                        filterPrimaryMetabolism = nil
                    }
                }

                if let structure = filterBiomechanicalStructure {
                    ExerciseFilterChip(title: structure.rawValue, systemImage: structure.icon) {
                        filterBiomechanicalStructure = nil
                    }
                }

                if let role = filterTrainingRole {
                    ExerciseFilterChip(title: role.rawValue, systemImage: role.icon) {
                        filterTrainingRole = nil
                    }
                }

                if let category = filterCategory {
                    ExerciseFilterChip(title: category.rawValue, systemImage: category.icon) {
                        filterCategory = nil
                    }
                }

                if let plane = filterReferencePlane {
                    ExerciseFilterChip(title: plane.rawValue, systemImage: plane.icon) {
                        filterReferencePlane = nil
                    }
                }

                ForEach(filterMotorSchemas.sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { schema in
                    ExerciseFilterChip(title: schema.rawValue, systemImage: schema.icon) {
                        filterMotorSchemas.remove(schema)
                    }
                }

                ForEach(filterTags.sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { tag in
                    ExerciseFilterChip(title: tag.rawValue, systemImage: tag.icon) {
                        filterTags.remove(tag)
                    }
                }

                if filterFavoritesOnly {
                    ExerciseFilterChip(title: "Preferiti", systemImage: "star.fill") {
                        filterFavoritesOnly = false
                    }
                }

                Button("Reset", role: .destructive, action: onClearAll)
                    .buttonStyle(.bordered)
                    .font(.caption)
            }
            .padding(.vertical, 8)
        }
    }
}

struct ExerciseFilterChip: View {
    let title: String
    var systemImage: String?
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
                    .lineLimit(1)
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2)
            }
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.accentColor.opacity(0.15))
            )
        }
        .buttonStyle(.plain)
    }
}
