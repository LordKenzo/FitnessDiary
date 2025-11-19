import SwiftUI
import SwiftData

struct AddWorkoutCardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @AppStorage("debugWorkoutLogEnabled") private var debugWorkoutLogEnabled = false

    let folders: [WorkoutFolder]
    let clients: [Client]

    @State private var name = ""
    @State private var description = ""
    @State private var targetExpression: StrengthExpressionType? = nil
    @State private var selectedFolders: [WorkoutFolder] = []
    @State private var isAssignedToMe = true
    @State private var selectedClients: [Client] = []
    @State private var workoutBlocks: [WorkoutBlockData] = []
    @State private var showingExercisePicker = false
    @State private var showingMethodSelection = false
    @State private var showingAddBlockMenu = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 20) {
                        // MARK: - Information Section (Hero Card)
                        informationSection

                        // MARK: - Goal Section
                        goalSection

                        // MARK: - Organization Section
                        organizationSection

                        // MARK: - Blocks Section
                        blocksSection

                        // Debug section
                        if debugWorkoutLogEnabled && !workoutBlocks.isEmpty {
                            debugSection
                        }

                        // Bottom spacing for FAB
                        Color.clear.frame(height: 80)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
                .scrollDismissesKeyboard(.interactively)

                // MARK: - Floating Action Button
                if !showingAddBlockMenu {
                    FloatingActionButton(icon: "plus.circle.fill", label: "Aggiungi Blocco") {
                        showingAddBlockMenu = true
                    }
                    .padding(.bottom, 20)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .navigationTitle("Nuova Scheda")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        saveCard()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.isEmpty)
                }
            }
            .sheet(isPresented: $showingExercisePicker) {
                ExercisePickerView(
                    exercises: exercises,
                    onSelect: { exercise in
                        addSimpleBlock(exercise)
                    }
                )
            }
            .sheet(isPresented: $showingMethodSelection) {
                MethodSelectionView { method in
                    addMethodBlock(method)
                }
            }
            .confirmationDialog("Aggiungi Blocco", isPresented: $showingAddBlockMenu) {
                Button {
                    showingExercisePicker = true
                } label: {
                    Label("Esercizio Singolo", systemImage: "figure.strengthtraining.traditional")
                }

                Button {
                    showingMethodSelection = true
                } label: {
                    Label("Con Metodo", systemImage: "bolt.horizontal.fill")
                }

                Button {
                    addRestBlock()
                } label: {
                    Label("Riposo", systemImage: "moon.zzz.fill")
                }

                Button("Annulla", role: .cancel) {}
            }
        }
        .appScreenBackground()
    }

    // MARK: - Information Section
    private var informationSection: some View {
        SectionCard(title: "Informazioni") {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Nome scheda")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)

                    TextField("Es: Push Day, Full Body...", text: $name)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.white.opacity(0.05))
                        )
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Descrizione (opzionale)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)

                    TextField("Aggiungi dettagli sulla scheda...", text: $description, axis: .vertical)
                        .font(.subheadline)
                        .textFieldStyle(.plain)
                        .lineLimit(2...4)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.white.opacity(0.05))
                        )
                }
            }
        }
    }

    // MARK: - Goal Section
    private var goalSection: some View {
        SectionCard(title: "Obiettivo della scheda") {
            VStack(spacing: 16) {
                // Grid of selectable chips
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    // "Nessuno" option
                    SelectableChip(
                        icon: "minus.circle",
                        label: "Nessuno",
                        color: .gray,
                        isSelected: targetExpression == nil,
                        action: { targetExpression = nil }
                    )

                    ForEach(StrengthExpressionType.allCases) { type in
                        SelectableChip(
                            icon: type.icon,
                            label: type.displayName,
                            color: type.color,
                            isSelected: targetExpression == type,
                            action: { targetExpression = type }
                        )
                    }
                }

                // Info text
                Text("Il target definisce i range consigliati per carichi, ripetizioni e recuperi su tutta la scheda.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
        }
    }

    // MARK: - Organization Section
    private var organizationSection: some View {
        SectionCard(title: "Organizzazione") {
            VStack(spacing: 14) {
                folderSelectionRow
                myToggleRow
                clientSelectionRow
            }
        }
    }

    private var folderSelectionRow: some View {
        NavigationLink {
            FolderSelectionView(
                selectedFolders: $selectedFolders,
                folders: folders
            )
        } label: {
            OrganizationRow(
                icon: "folder.fill",
                iconColor: .orange,
                title: "Folder",
                isEmpty: selectedFolders.isEmpty,
                emptyText: "Nessuna cartella selezionata",
                badges: selectedFolders.prefix(2).map { ($0.name, Color.orange) },
                extraCount: selectedFolders.count > 2 ? selectedFolders.count - 2 : 0
            )
        }
        .buttonStyle(.plain)
    }

    private var myToggleRow: some View {
        HStack {
            Image(systemName: "person.fill")
                .font(.subheadline)
                .foregroundStyle(.blue)

            Text("Mia")
                .font(.subheadline)
                .fontWeight(.medium)

            Spacer()

            Toggle("", isOn: $isAssignedToMe)
                .labelsHidden()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
    }

    private var clientSelectionRow: some View {
        NavigationLink {
            ClientSelectionView(
                selectedClients: $selectedClients,
                clients: clients
            )
        } label: {
            OrganizationRow(
                icon: "person.2.fill",
                iconColor: .green,
                title: "Assegnata a clienti",
                isEmpty: selectedClients.isEmpty,
                emptyText: "Nessun cliente selezionato",
                badges: selectedClients.prefix(2).map { ($0.name, Color.green) },
                extraCount: selectedClients.count > 2 ? selectedClients.count - 2 : 0
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Blocks Section
    private var blocksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Blocchi")
                    .font(.headline)
                    .fontWeight(.semibold)

                Text("(\(workoutBlocks.count))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                if !workoutBlocks.isEmpty {
                    EditButton()
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            .padding(.horizontal, 4)

            if workoutBlocks.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "dumbbell")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary.opacity(0.5))

                    Text("Nessun blocco aggiunto")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("Tocca il pulsante in basso per iniziare")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.white.opacity(0.03))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5]))
                                .foregroundStyle(.secondary.opacity(0.3))
                        )
                )
            } else {
                VStack(spacing: 10) {
                    ForEach(workoutBlocks.indices, id: \.self) { index in
                        NavigationLink {
                            EditWorkoutBlockView(
                                blockData: $workoutBlocks[index],
                                cardTargetExpression: targetExpression
                            )
                        } label: {
                            EnhancedBlockRow(
                                block: workoutBlockToModel(workoutBlocks[index]),
                                order: index + 1
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .onMove(perform: moveBlock)
                    .onDelete(perform: deleteBlock)
                }
            }
        }
    }

    // MARK: - Debug Section
    private var debugSection: some View {
        SectionCard(title: "Debug") {
            NavigationLink {
                WorkoutDebugLogView(blockData: workoutBlocks)
            } label: {
                HStack {
                    Image(systemName: "list.bullet.rectangle")
                        .foregroundStyle(.purple)
                    Text("Anteprima sequenza esercizi")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)
        }
    }

    private func addSimpleBlock(_ exercise: Exercise) {
        WorkoutBlockHelper.addSimpleBlock(to: &workoutBlocks, exercise: exercise)
    }

    private func addMethodBlock(_ method: MethodType) {
        WorkoutBlockHelper.addMethodBlock(to: &workoutBlocks, method: method)
    }

    private func addRestBlock() {
        WorkoutBlockHelper.addRestBlock(to: &workoutBlocks)
    }

    private func moveBlock(from source: IndexSet, to destination: Int) {
        WorkoutBlockHelper.moveBlock(in: &workoutBlocks, from: source, to: destination)
    }

    private func deleteBlock(at offsets: IndexSet) {
        WorkoutBlockHelper.deleteBlock(in: &workoutBlocks, at: offsets)
    }

    // Helper to convert WorkoutBlockData to WorkoutBlock for preview
    private func workoutBlockToModel(_ blockData: WorkoutBlockData) -> WorkoutBlock {
        return WorkoutBlockHelper.workoutBlockToModel(blockData)
    }

    private func saveCard() {
        let newCard = WorkoutCard(
            name: name,
            description: description.isEmpty ? nil : description,
            targetExpression: targetExpression,
            folders: selectedFolders,
            isAssignedToMe: isAssignedToMe,
            assignedTo: selectedClients
        )

        // Crea i blocchi usando WorkoutBlockHelper
        // Questo elimina la duplicazione di codice e centralizza la logica di conversione
        for blockData in workoutBlocks {
            let block = WorkoutBlockHelper.workoutBlockToModel(blockData)
            newCard.blocks.append(block)
        }

        modelContext.insert(newCard)
        dismiss()
    }
}

// Row component for exercise display
struct WorkoutExerciseRow: View {
    let exerciseData: WorkoutExerciseItemData
    let order: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("\(order).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 24, alignment: .leading)
                Text(exerciseData.exercise.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            HStack(spacing: 12) {
                Label("\(exerciseData.sets.count) serie", systemImage: "number")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let restTime = exerciseData.restTime {
                    let minutes = Int(restTime) / 60
                    let seconds = Int(restTime) % 60
                    if minutes > 0 {
                        Label("\(minutes)m \(seconds)s", systemImage: "clock")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Label("\(seconds)s", systemImage: "clock")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.leading, 24)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    AddWorkoutCardView(folders: [], clients: [])
        .modelContainer(for: [WorkoutCard.self, Exercise.self])
}
