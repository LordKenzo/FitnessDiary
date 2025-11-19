import SwiftUI

struct ExerciseQuickLookView: View {
    @Environment(\.dismiss) private var dismiss
    let exercise: Exercise

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    photoSection
                    focusSection
                    metadataSection
                    musclesSection
                    tagsSection
                    descriptionSection
                    linkSection
                }
                .padding()
            }
            .navigationTitle(exercise.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("common.close")) { dismiss() }
                }
            }
        }
        .appScreenBackground()
    }

    @ViewBuilder
    private var photoSection: some View {
        if let photoData = exercise.photo1Data, let uiImage = UIImage(data: photoData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.accentColor.opacity(0.2), lineWidth: 1)
                )
        } else {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.15))
                .frame(height: 180)
                .overlay {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                }
        }
    }

    @ViewBuilder
    private var focusSection: some View {
        if let focus = exercise.focusOn, !focus.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Label("Focus", systemImage: "scope")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(focus)
                    .font(.body)
            }
        }
    }

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if exercise.isFavorite {
                MetadataChip(title: "Preferito", systemImage: "star.fill", tint: .yellow)
            }

            HStack(spacing: 8) {
                MetadataChip(title: exercise.trainingRole.rawValue, systemImage: exercise.trainingRole.icon, tint: exercise.trainingRole.color)
                MetadataChip(title: exercise.category.rawValue, systemImage: exercise.category.icon, tint: exercise.category.color)
            }

            HStack(spacing: 8) {
                MetadataChip(title: exercise.biomechanicalStructure.rawValue, systemImage: exercise.biomechanicalStructure.icon, tint: .blue)
                MetadataChip(title: exercise.primaryMetabolism.rawValue, systemImage: exercise.primaryMetabolism.icon, tint: exercise.primaryMetabolism.color)
            }

            if let plane = exercise.referencePlane {
                MetadataChip(title: plane.rawValue, systemImage: plane.icon, tint: plane.color)
            }

            if !exercise.motorSchemas.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Schemi motori")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 8) {
                        ForEach(exercise.motorSchemas.sorted(by: { $0.rawValue < $1.rawValue })) { schema in
                            MetadataChip(title: schema.rawValue, systemImage: schema.icon, tint: schema.color)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var musclesSection: some View {
        if !exercise.primaryMuscles.isEmpty || !exercise.secondaryMuscles.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Muscoli coinvolti")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !exercise.primaryMuscles.isEmpty {
                    Text("Primari: " + exercise.primaryMuscles.map { $0.name }.joined(separator: ", "))
                        .font(.subheadline)
                }
                if !exercise.secondaryMuscles.isEmpty {
                    Text("Secondari: " + exercise.secondaryMuscles.map { $0.name }.joined(separator: ", "))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private var tagsSection: some View {
        if !exercise.tags.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Tag")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 8)], spacing: 8) {
                    ForEach(exercise.tags.sorted(by: { $0.rawValue < $1.rawValue })) { tag in
                        MetadataChip(title: tag.rawValue, systemImage: tag.icon, tint: tag.color)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var descriptionSection: some View {
        if let description = exercise.exerciseDescription, !description.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Descrizione")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(description)
                    .font(.body)
            }
        }
    }

    @ViewBuilder
    private var linkSection: some View {
        if let urlString = exercise.youtubeURL, let url = URL(string: urlString) {
            Link(destination: url) {
                Label("Apri video", systemImage: "play.rectangle")
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

