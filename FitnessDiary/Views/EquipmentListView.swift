import SwiftUI
import SwiftData

struct EquipmentListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Equipment.name) private var equipment: [Equipment]
    @State private var showingAddEquipment = false
    @State private var selectedEquipment: Equipment?

    private var equipmentByCategory: [EquipmentCategory: [Equipment]] {
        Dictionary(grouping: equipment, by: { $0.category })
    }

    var body: some View {
        List {
            if equipment.isEmpty {
                ContentUnavailableView {
                    Label("Nessun attrezzo", systemImage: "dumbbell")
                } description: {
                    Text("Inizializza il database con gli attrezzi predefiniti o aggiungine di nuovi")
                } actions: {
                    Button("Inizializza Database") {
                        initializeDefaultEquipment()
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                ForEach(EquipmentCategory.allCases, id: \.self) { category in
                    if let equipmentInCategory = equipmentByCategory[category], !equipmentInCategory.isEmpty {
                        Section {
                            ForEach(equipmentInCategory) { item in
                                HStack {
                                    Text(item.name)
                                    Spacer()
                                    Text(item.category.rawValue)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedEquipment = item
                                }
                            }
                            .onDelete { indexSet in
                                deleteEquipment(from: equipmentInCategory, at: indexSet)
                            }
                        } header: {
                            Label(category.rawValue, systemImage: category.icon)
                        }
                    }
                }
            }
        }
        .navigationTitle("Attrezzi")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingAddEquipment = true
                    } label: {
                        Label("Aggiungi Attrezzo", systemImage: "plus")
                    }

                    if !equipment.isEmpty {
                        Divider()
                        Button(role: .destructive) {
                            deleteAllEquipment()
                        } label: {
                            Label("Elimina Tutti", systemImage: "trash")
                        }
                    }

                    if equipment.isEmpty {
                        Divider()
                        Button {
                            initializeDefaultEquipment()
                        } label: {
                            Label("Inizializza Database", systemImage: "arrow.clockwise")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingAddEquipment) {
            AddEquipmentView()
        }
        .sheet(item: $selectedEquipment) { equipment in
            EditEquipmentView(equipment: equipment)
        }
    }

    private func deleteEquipment(from equipment: [Equipment], at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(equipment[index])
        }
    }

    private func deleteAllEquipment() {
        for item in equipment {
            modelContext.delete(item)
        }
    }

    private func initializeDefaultEquipment() {
        let defaultEquipment: [(String, EquipmentCategory)] = [
            // Corpo Libero
            ("Nessun attrezzo", .bodyweight),

            // Bilanciere
            ("Bilanciere Olimpico", .barbell),
            ("Bilanciere EZ", .barbell),
            ("Trap Bar", .barbell),

            // Manubri
            ("Manubri", .dumbbell),

            // Macchine
            ("Leg Press", .machine),
            ("Lat Machine", .machine),
            ("Chest Press", .machine),
            ("Leg Extension", .machine),
            ("Leg Curl", .machine),
            ("Shoulder Press", .machine),
            ("Cable Crossover", .machine),
            ("Smith Machine", .machine),
            ("Hack Squat", .machine),

            // Kettlebell
            ("Kettlebell", .kettlebell),

            // Cavi
            ("Cavi", .cable),
            ("Pulegge", .cable),

            // Bande Elastiche
            ("Elastici", .band),
            ("Bande di Resistenza", .band),

            // TRX
            ("TRX", .trx),
            ("Anelli", .trx),

            // Cardio
            ("Tapis Roulant", .cardio),
            ("Cyclette", .cardio),
            ("Ellittica", .cardio),
            ("Vogatore", .cardio),
            ("Step", .cardio),
            ("Air Bike", .cardio),
            ("Spin Bike", .cardio),

            // Altro
            ("Panca", .other),
            ("Pull-up Bar", .other),
            ("Parallele", .other),
            ("Sacco da Boxe", .other),
            ("Corda per Saltare", .other),
            ("Foam Roller", .other),
            ("Medicine Ball", .other),
            ("Palla Svizzera", .other),
            ("Sandbag", .other),
            ("Battle Rope", .other),
        ]

        for (name, category) in defaultEquipment {
            let equipment = Equipment(name: name, category: category)
            modelContext.insert(equipment)
        }
    }
}

struct AddEquipmentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var selectedCategory: EquipmentCategory = .other

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Nome attrezzo", text: $name)

                    Picker("Categoria", selection: $selectedCategory) {
                        ForEach(EquipmentCategory.allCases, id: \.self) { category in
                            Label(category.rawValue, systemImage: category.icon)
                                .tag(category)
                        }
                    }
                }
            }
            .navigationTitle("Nuovo Attrezzo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        saveEquipment()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func saveEquipment() {
        let equipment = Equipment(name: name, category: selectedCategory)
        modelContext.insert(equipment)
        dismiss()
    }
}

struct EditEquipmentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var equipment: Equipment

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Nome attrezzo", text: $equipment.name)

                    Picker("Categoria", selection: $equipment.category) {
                        ForEach(EquipmentCategory.allCases, id: \.self) { category in
                            Label(category.rawValue, systemImage: category.icon)
                                .tag(category)
                        }
                    }
                }

                Section {
                    Button("Elimina Attrezzo", role: .destructive) {
                        deleteEquipment()
                    }
                }
            }
            .navigationTitle("Modifica Attrezzo")
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

    private func deleteEquipment() {
        modelContext.delete(equipment)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        EquipmentListView()
    }
    .modelContainer(for: Equipment.self, inMemory: true)
}
