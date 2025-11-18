import SwiftUI

struct MotorSchemaSelectionView: View {
    @Binding var selection: Set<MotorSchema>
    private let selectionLimit = 3

    var body: some View {
        List {
            Section {
                ForEach(MotorSchema.allCases) { schema in
                    Button {
                        toggleSelection(schema)
                    } label: {
                        HStack {
                            Label(schema.rawValue, systemImage: schema.icon)
                                .foregroundStyle(schema.color)
                            Spacer()
                            if selection.contains(schema) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.accentColor)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(!selection.contains(schema) && selection.count >= selectionLimit)
                }
            } footer: {
                Text("Puoi selezionare al massimo \(selectionLimit) schemi motori")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Schemi Motori")
    }

    private func toggleSelection(_ schema: MotorSchema) {
        if selection.contains(schema) {
            selection.remove(schema)
        } else if selection.count < selectionLimit {
            selection.insert(schema)
        }
    }
}

struct ExerciseTagSelectionView: View {
    @Binding var selection: Set<ExerciseTag>

    var body: some View {
        List {
            Section {
                ForEach(ExerciseTag.allCases) { tag in
                    Button {
                        toggleSelection(tag)
                    } label: {
                        HStack {
                            Label(tag.rawValue, systemImage: tag.icon)
                                .foregroundStyle(tag.color)
                            Spacer()
                            if selection.contains(tag) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.accentColor)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle("Tag esercizio")
    }

    private func toggleSelection(_ tag: ExerciseTag) {
        if selection.contains(tag) {
            selection.remove(tag)
        } else {
            selection.insert(tag)
        }
    }
}

struct MetadataChip: View {
    let title: String
    let systemImage: String
    let tint: Color

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(tint.opacity(0.15))
            .foregroundStyle(tint)
            .clipShape(Capsule())
    }
}
