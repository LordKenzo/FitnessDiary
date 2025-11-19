import SwiftUI
import SwiftData

struct MuscleListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Muscle.name) private var muscles: [Muscle]
    @State private var showingAddMuscle = false
    @State private var selectedMuscle: Muscle?
    @ObservedObject private var localizationManager = LocalizationManager.shared

    private var musclesByCategory: [MuscleCategory: [Muscle]] {
        Dictionary(grouping: muscles, by: { $0.category })
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                if muscles.isEmpty {
                    GlassEmptyStateCard(
                        systemImage: "figure.arms.open",
                        title: L("muscles.no.muscles"),
                        description: L("muscles.no.muscles.description")
                    ) {
                        Button(L("muscles.initialize")) {
                            initializeDefaultMuscles()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    ForEach(MuscleCategory.allCases, id: \.self) { category in
                        if let musclesInCategory = musclesByCategory[category], !musclesInCategory.isEmpty {
                            GlassSectionCard(title: category.rawValue, iconName: category.icon) {
                                ForEach(musclesInCategory) { muscle in
                                    GlassListRow(title: muscle.name, subtitle: category.rawValue, iconName: category.icon) {
                                        menuButton(for: muscle)
                                    }
                                    .onTapGesture {
                                        selectedMuscle = muscle
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .navigationTitle(L("muscles.title"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingAddMuscle = true
                    } label: {
                        Label(L("muscles.add"), systemImage: "plus")
                    }

                    if !muscles.isEmpty {
                        Divider()
                        Button(role: .destructive) {
                            deleteAllMuscles()
                        } label: {
                            Label(L("muscles.delete.all"), systemImage: "trash")
                        }
                    }

                    if muscles.isEmpty {
                        Divider()
                        Button {
                            initializeDefaultMuscles()
                        } label: {
                            Label(L("muscles.initialize"), systemImage: "arrow.clockwise")
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
        .appScreenBackground()
    }

    private func deleteAllMuscles() {
        for muscle in muscles {
            modelContext.delete(muscle)
        }
    }

    private func deleteMuscle(_ muscle: Muscle) {
        modelContext.delete(muscle)
    }

    @ViewBuilder
    private func menuButton(for muscle: Muscle) -> some View {
        Menu {
            Button(L("common.edit")) {
                selectedMuscle = muscle
            }

            Button(role: .destructive) {
                deleteMuscle(muscle)
            } label: {
                Label(L("common.delete"), systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.title3)
                .foregroundStyle(.secondary)
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
                    TextField(L("muscles.name"), text: $name)

                    Picker(L("muscles.category"), selection: $selectedCategory) {
                        ForEach(MuscleCategory.allCases, id: \.self) { category in
                            Label(category.rawValue, systemImage: category.icon)
                                .tag(category)
                        }
                    }
                }
            }
            .navigationTitle(L("muscles.new.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("common.cancel")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(L("common.save")) {
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
                    TextField(L("muscles.name"), text: $muscle.name)

                    Picker(L("muscles.category"), selection: $muscle.category) {
                        ForEach(MuscleCategory.allCases, id: \.self) { category in
                            Label(category.rawValue, systemImage: category.icon)
                                .tag(category)
                        }
                    }
                }

                Section {
                    Button(L("muscles.delete.action"), role: .destructive) {
                        deleteMuscle()
                    }
                }
            }
            .navigationTitle(L("muscles.edit.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("common.done")) {
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
