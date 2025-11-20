import SwiftUI
import SwiftData

struct EditWorkoutCardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @AppStorage("debugWorkoutLogEnabled") private var debugWorkoutLogEnabled = false

    @Bindable var card: WorkoutCard
    let folders: [WorkoutFolder]
    let clients: [Client]

    @State private var name: String
    @State private var description: String
    @State private var targetExpression: StrengthExpressionType?
    @State private var selectedFolders: [WorkoutFolder]
    @State private var isAssignedToMe: Bool
    @State private var selectedClients: [Client]
    @State private var workoutBlocks: [WorkoutBlockData] = []
    @State private var showingExercisePicker = false
    @State private var showingMethodSelection = false
    @State private var showingAddBlockMenu = false

    init(card: WorkoutCard, folders: [WorkoutFolder], clients: [Client]) {
        self.card = card
        self.folders = folders
        self.clients = clients
        _name = State(initialValue: card.name)
        _description = State(initialValue: card.cardDescription ?? "")
        _selectedFolders = State(initialValue: card.folders)
        _isAssignedToMe = State(initialValue: card.isAssignedToMe)
        _selectedClients = State(initialValue: card.assignedTo)
        _targetExpression = State(initialValue: card.targetExpression)

        // Converti i blocchi esistenti in WorkoutBlockData
        _workoutBlocks = State(initialValue: card.blocks.sorted(by: { $0.order < $1.order }).map { block in
            WorkoutBlockData(
                blockType: block.blockType,
                methodType: block.methodType,
                order: block.order,
                globalSets: block.globalSets,
                globalRestTime: block.globalRestTime,
                notes: block.notes,
                tabataWorkDuration: block.tabataWorkDuration,
                tabataRestDuration: block.tabataRestDuration,
                tabataRounds: block.tabataRounds,
                tabataRecoveryBetweenRounds: block.tabataRecoveryBetweenRounds,
                exerciseItems: block.exerciseItems.sorted(by: { $0.order < $1.order }).map { exerciseItem in
                    WorkoutExerciseItemData(
                        exercise: exerciseItem.exercise ?? Exercise(
                            name: "Esercizio Eliminato",
                            biomechanicalStructure: .multiJoint,
                            trainingRole: .base,
                            primaryMetabolism: .mixed,
                            category: .training
                        ),
                        order: exerciseItem.order,
                        sets: exerciseItem.sets.sorted(by: { $0.order < $1.order }).map { set in
                            WorkoutSetData(
                                order: set.order,
                                setType: set.setType,
                                reps: set.reps,
                                weight: set.weight,
                                duration: set.duration,
                                notes: set.notes,
                                loadType: set.loadType ?? .absolute,
                                percentageOfMax: set.percentageOfMax,
                                clusterSize: set.clusterSize,
                                clusterRestTime: set.clusterRestTime,
                                clusterProgression: set.clusterProgression,
                                clusterMinPercentage: set.clusterMinPercentage,
                                clusterMaxPercentage: set.clusterMaxPercentage,
                                restPauseCount: set.restPauseCount,
                                restPauseDuration: set.restPauseDuration
                            )
                        },
                        notes: exerciseItem.notes,
                        restTime: exerciseItem.restTime
                    )
                }
            )
        })
    }

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

                        // Delete button
                        deleteSection

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
            .navigationTitle("Modifica Scheda")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        saveChanges()
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
                Text("Imposta un target unico per guidare carichi, ripetizioni e recuperi di tutti gli esercizi della scheda.")
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
                badges: selectedClients.prefix(2).map { ($0.fullName, Color.green) },
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
                List {
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
                        .listRowInsets(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                    .onMove(perform: moveBlock)
                    .onDelete(perform: deleteBlock)
                }
                .listStyle(.plain)
                .frame(height: CGFloat(workoutBlocks.count) * 95) // Approximate height per row
                .scrollDisabled(true) // Disable list scroll, parent ScrollView handles it
            }
        }
    }

    // MARK: - Debug Section
    private var debugSection: some View {
        SectionCard(title: "Testo Scheda") {
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

    // MARK: - Delete Section
    private var deleteSection: some View {
        Button(role: .destructive) {
            deleteCard()
        } label: {
            HStack {
                Spacer()
                Label("Elimina Scheda", systemImage: "trash")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.red.opacity(0.15))
            )
        }
        .buttonStyle(.plain)
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

    private func saveChanges() {
        card.name = name
        card.cardDescription = description.isEmpty ? nil : description
        card.targetExpression = targetExpression
        card.folders = selectedFolders
        card.isAssignedToMe = isAssignedToMe
        card.assignedTo = selectedClients

        // Elimina esplicitamente tutti i blocchi esistenti dal database
        // (anche se @Relationship(deleteRule: .cascade) dovrebbe gestirlo automaticamente)
        for block in card.blocks {
            modelContext.delete(block)
        }
        card.blocks.removeAll()

        // Ricrea i blocchi dalla lista modificata usando WorkoutBlockHelper
        // Questo elimina la duplicazione di codice e centralizza la logica di conversione
        for blockData in workoutBlocks {
            let block = WorkoutBlockHelper.workoutBlockToModel(blockData)
            card.blocks.append(block)
        }

        dismiss()
    }

    private func deleteCard() {
        modelContext.delete(card)
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    guard let container = try? ModelContainer(for: WorkoutCard.self, Exercise.self, configurations: config) else {
        fatalError("Failed to create preview ModelContainer")
    }

    let exercise = Exercise(
        name: "Panca Piana",
        biomechanicalStructure: .multiJoint,
        trainingRole: .fundamental,
        primaryMetabolism: .anaerobic,
        category: .training
    )

    let card = WorkoutCard(name: "Forza A")
    container.mainContext.insert(card)
    container.mainContext.insert(exercise)

    return EditWorkoutCardView(card: card, folders: [], clients: [])
        .modelContainer(container)
}
