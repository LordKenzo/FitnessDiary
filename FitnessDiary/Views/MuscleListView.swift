import SwiftUI
import SwiftData

struct MuscleListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Muscle.name) private var muscles: [Muscle]
    @State private var showingAddMuscle = false
    @State private var selectedMuscle: Muscle?

    private var musclesByCategory: [MuscleCategory: [Muscle]] {
        Dictionary(grouping: muscles, by: { $0.category })
    }

    var body: some View {
        List {
            if muscles.isEmpty {
                ContentUnavailableView {
                    Label("Nessun muscolo", systemImage: "figure.arms.open")
                } description: {
                    Text("Inizializza il database con i muscoli predefiniti o aggiungine di nuovi")
                } actions: {
                    Button("Inizializza Database") {
                        initializeDefaultMuscles()
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                ForEach(MuscleCategory.allCases, id: \.self) { category in
                    if let musclesInCategory = musclesByCategory[category], !musclesInCategory.isEmpty {
                        Section {
                            ForEach(musclesInCategory) { muscle in
                                HStack {
                                    Text(muscle.name)
                                    Spacer()
                                    Text(muscle.category.rawValue)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedMuscle = muscle
                                }
                            }
                            .onDelete { indexSet in
                                deleteMuscles(from: musclesInCategory, at: indexSet)
                            }
                        } header: {
                            Label(category.rawValue, systemImage: category.icon)
                        }
                    }
                }
            }
        }
        .navigationTitle("Muscoli")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingAddMuscle = true
                    } label: {
                        Label("Aggiungi Muscolo", systemImage: "plus")
                    }

                    if !muscles.isEmpty {
                        Divider()
                        Button(role: .destructive) {
                            deleteAllMuscles()
                        } label: {
                            Label("Elimina Tutti", systemImage: "trash")
                        }
                    }

                    if muscles.isEmpty {
                        Divider()
                        Button {
                            initializeDefaultMuscles()
                        } label: {
                            Label("Inizializza Database", systemImage: "arrow.clockwise")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingAddMuscle) {
            AddMuscleView()
        }
        .sheet(item: $selectedMuscle) { muscle in
            EditMuscleView(muscle: muscle)
        }
    }

    private func deleteMuscles(from muscles: [Muscle], at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(muscles[index])
        }
    }

    private func deleteAllMuscles() {
        for muscle in muscles {
            modelContext.delete(muscle)
        }
    }

    private func initializeDefaultMuscles() {
        let defaultMuscles: [(String, MuscleCategory)] = [
            // Petto
            ("Pettorale Maggiore", .chest),
            ("Pettorale Minore", .chest),

            // Schiena
            ("Gran Dorsale", .back),
            ("Trapezio", .back),
            ("Romboidi", .back),
            ("Erettori Spinali", .back),

            // Spalle
            ("Deltoide Anteriore", .shoulders),
            ("Deltoide Laterale", .shoulders),
            ("Deltoide Posteriore", .shoulders),

            // Braccia
            ("Bicipite Brachiale", .biceps),
            ("Brachiale", .biceps),
            ("Tricipite Brachiale", .triceps),
            ("Brachioradiale", .forearms),
            ("Flessori del Polso", .forearms),
            ("Estensori del Polso", .forearms),

            // Core
            ("Retto dell'Addome", .abs),
            ("Obliquo Esterno", .abs),
            ("Obliquo Interno", .abs),
            ("Trasverso dell'Addome", .abs),

            // Gambe
            ("Retto Femorale", .quadriceps),
            ("Vasto Laterale", .quadriceps),
            ("Vasto Mediale", .quadriceps),
            ("Vasto Intermedio", .quadriceps),
            ("Bicipite Femorale", .hamstrings),
            ("Semitendinoso", .hamstrings),
            ("Semimembranoso", .hamstrings),
            ("Grande Gluteo", .glutes),
            ("Medio Gluteo", .glutes),
            ("Piccolo Gluteo", .glutes),
            ("Gastrocnemio", .calves),
            ("Soleo", .calves),
        ]

        for (name, category) in defaultMuscles {
            let muscle = Muscle(name: name, category: category)
            modelContext.insert(muscle)
        }
    }
}

struct AddMuscleView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var selectedCategory: MuscleCategory = .chest

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Nome muscolo", text: $name)

                    Picker("Categoria", selection: $selectedCategory) {
                        ForEach(MuscleCategory.allCases, id: \.self) { category in
                            Label(category.rawValue, systemImage: category.icon)
                                .tag(category)
                        }
                    }
                }
            }
            .navigationTitle("Nuovo Muscolo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        saveMuscle()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func saveMuscle() {
        let muscle = Muscle(name: name, category: selectedCategory)
        modelContext.insert(muscle)
        dismiss()
    }
}

struct EditMuscleView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var muscle: Muscle

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Nome muscolo", text: $muscle.name)

                    Picker("Categoria", selection: $muscle.category) {
                        ForEach(MuscleCategory.allCases, id: \.self) { category in
                            Label(category.rawValue, systemImage: category.icon)
                                .tag(category)
                        }
                    }
                }

                Section {
                    Button("Elimina Muscolo", role: .destructive) {
                        deleteMuscle()
                    }
                }
            }
            .navigationTitle("Modifica Muscolo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fatto") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func deleteMuscle() {
        modelContext.delete(muscle)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        MuscleListView()
    }
    .modelContainer(for: Muscle.self, inMemory: true)
}
