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
        ScrollView {
            VStack(spacing: 22) {
                if equipment.isEmpty {
                    GlassEmptyStateCard(
                        systemImage: "dumbbell",
                        title: L("equipment.no.equipment"),
                        description: L("equipment.no.equipment.description")
                    ) {
                        Button(L("equipment.initialize")) {
                            initializeDefaultEquipment()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    ForEach(EquipmentCategory.allCases, id: \.self) { category in
                        if let equipmentInCategory = equipmentByCategory[category], !equipmentInCategory.isEmpty {
                            GlassSectionCard(title: category.rawValue, iconName: category.icon) {
                                ForEach(equipmentInCategory) { item in
                                    GlassListRow(title: item.name, subtitle: item.category.rawValue, iconName: category.icon) {
                                        menuButton(for: item)
                                    }
                                    .onTapGesture {
                                        selectedEquipment = item
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
        .navigationTitle(L("equipment.title"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingAddEquipment = true
                    } label: {
                        Label(L("equipment.add"), systemImage: "plus")
                    }

                    if !equipment.isEmpty {
                        Divider()
                        Button(role: .destructive) {
                            deleteAllEquipment()
                        } label: {
                            Label(L("equipment.delete.all"), systemImage: "trash")
                        }
                    }

                    if equipment.isEmpty {
                        Divider()
                        Button {
                            initializeDefaultEquipment()
                        } label: {
                            Label(L("equipment.initialize"), systemImage: "arrow.clockwise")
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
        .appScreenBackground()
    }

    private func deleteAllEquipment() {
        for item in equipment {
            modelContext.delete(item)
        }
    }

    private func deleteEquipment(_ equipment: Equipment) {
        modelContext.delete(equipment)
    }

    @ViewBuilder
    private func menuButton(for equipment: Equipment) -> some View {
        Menu {
            Button(L("common.edit")) {
                selectedEquipment = equipment
            }

            Button(role: .destructive) {
                deleteEquipment(equipment)
            } label: {
                Label(L("common.delete"), systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.title3)
                .foregroundStyle(.secondary)
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
            ScrollView {
                VStack(spacing: 20) {
                    // Name Section
                    SectionCard(title: L("equipment.name")) {
                        TextField(L("equipment.name.placeholder"), text: $name)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.white.opacity(0.05))
                            )
                    }

                    // Category Section
                    SectionCard(title: L("equipment.category")) {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(EquipmentCategory.allCases, id: \.self) { category in
                                CategoryChip(
                                    icon: category.icon,
                                    label: category.rawValue,
                                    isSelected: selectedCategory == category,
                                    action: { selectedCategory = category }
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            .navigationTitle(L("equipment.new.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("common.cancel")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(L("common.save")) {
                        saveEquipment()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .appScreenBackground()
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
            ScrollView {
                VStack(spacing: 20) {
                    // Name Section
                    SectionCard(title: L("equipment.name")) {
                        TextField(L("equipment.name.placeholder"), text: $equipment.name)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.white.opacity(0.05))
                            )
                    }

                    // Category Section
                    SectionCard(title: L("equipment.category")) {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(EquipmentCategory.allCases, id: \.self) { category in
                                CategoryChip(
                                    icon: category.icon,
                                    label: category.rawValue,
                                    isSelected: equipment.category == category,
                                    action: { equipment.category = category }
                                )
                            }
                        }
                    }

                    // Delete Button
                    Button(role: .destructive) {
                        deleteEquipment()
                    } label: {
                        HStack {
                            Spacer()
                            Label(L("equipment.delete.action"), systemImage: "trash")
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
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            .navigationTitle(L("equipment.edit.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("common.done")) {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .appScreenBackground()
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
