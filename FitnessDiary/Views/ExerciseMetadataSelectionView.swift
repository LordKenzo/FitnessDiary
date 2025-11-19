import SwiftUI

struct MotorSchemaSelectionView: View {
    @Binding var selection: Set<MotorSchema>
    private let selectionLimit = 3

    var body: some View {
        List {
            Section {
                ForEach(MotorSchema.allCases) { schema in
                    schemaRow(schema)
                }
            } footer: {
                Text(String(format: L("metadata.motor.limit"), selectionLimit))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(L("metadata.motor.title"))
    }

    private func toggleSelection(_ schema: MotorSchema) {
        if selection.contains(schema) {
            selection.remove(schema)
        } else if selection.count < selectionLimit {
            selection.insert(schema)
        }
    }

    @ViewBuilder
    private func schemaRow(_ schema: MotorSchema) -> some View {
        Button {
            toggleSelection(schema)
        } label: {
            HStack {
                Label(schema.rawValue, systemImage: schema.icon)
                    .foregroundStyle(schema.color)
                Spacer()
                if selection.contains(schema) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(!selection.contains(schema) && selection.count >= selectionLimit)
    }
}

struct ExerciseTagSelectionView: View {
    @Binding var selection: Set<ExerciseTag>

    var body: some View {
        List {
            Section {
                ForEach(ExerciseTag.allCases) { tag in
                    tagRow(tag)
                }
            }
        }
        .navigationTitle(L("metadata.tags.title"))
    }

    @ViewBuilder
    private func tagRow(_ tag: ExerciseTag) -> some View {
        Button {
            toggleSelection(tag)
        } label: {
            HStack {
                Label(tag.rawValue, systemImage: tag.icon)
                    .foregroundStyle(tag.color)
                Spacer()
                if selection.contains(tag) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
        .buttonStyle(.plain)
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
