import SwiftUI
import SwiftData

// MARK: - Labeled Picker
struct LabeledPicker<T: Hashable, Content: View>: View {
    let label: String
    @Binding var selection: T
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.top, 4)

            Picker(label, selection: $selection) {
                content()
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.05))
            )
        }
    }
}

// MARK: - Exercise Taxonomy Section
struct ExerciseTaxonomySection: View {
    @Binding var biomechanicalStructure: BiomechanicalStructure
    @Binding var trainingRole: TrainingRole
    @Binding var primaryMetabolism: PrimaryMetabolism
    @Binding var category: ExerciseCategory

    var body: some View {
        SectionCard(title: "Tassonomia") {
            VStack(spacing: 12) {
                LabeledPicker(label: "Struttura Biomeccanica", selection: $biomechanicalStructure) {
                    ForEach(BiomechanicalStructure.allCases, id: \.self) { type in
                        Label(type.rawValue, systemImage: type.icon).tag(type)
                    }
                }

                LabeledPicker(label: "Ruolo nell'Allenamento", selection: $trainingRole) {
                    ForEach(TrainingRole.allCases, id: \.self) { role in
                        Label(role.rawValue, systemImage: role.icon).tag(role)
                    }
                }

                LabeledPicker(label: "Metabolismo Primario", selection: $primaryMetabolism) {
                    ForEach(PrimaryMetabolism.allCases, id: \.self) { metabolism in
                        Label(metabolism.rawValue, systemImage: metabolism.icon).tag(metabolism)
                    }
                }

                LabeledPicker(label: "Categoria", selection: $category) {
                    ForEach(ExerciseCategory.allCases, id: \.self) { cat in
                        Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                    }
                }
            }
        }
    }
}

// MARK: - Equipment Section
struct EquipmentPickerSection: View {
    @Binding var selectedEquipment: Equipment?
    let equipment: [Equipment]

    var body: some View {
        SectionCard(title: "Attrezzo") {
            LabeledPicker(label: "Seleziona attrezzo (opzionale)", selection: $selectedEquipment) {
                Text("Nessuno").tag(nil as Equipment?)
                ForEach(equipment) { item in
                    Label(item.name, systemImage: item.category.icon)
                        .tag(item as Equipment?)
                }
            }
        }
    }
}

// MARK: - Muscle Selection Row
struct MuscleSelectionRow: View {
    let title: String
    let icon: String
    let selectedMuscles: Set<Muscle>
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Label(title, systemImage: icon)
                    .foregroundStyle(.primary)
                Spacer()
                Text(selectedMuscles.isEmpty ? "Nessuno" : "\(selectedMuscles.count)")
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
        }
        .buttonStyle(.plain)

        if !selectedMuscles.isEmpty {
            Text(selectedMuscles.map { $0.name }.sorted().joined(separator: ", "))
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Selection Row (for NavigationLink items)
struct SelectionRow: View {
    let title: String
    let icon: String
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Label(title, systemImage: icon)
                    .foregroundStyle(.primary)
                Spacer()
                Text(count == 0 ? "Nessuno" : "\(count)")
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
        }
        .buttonStyle(.plain)
    }
}
