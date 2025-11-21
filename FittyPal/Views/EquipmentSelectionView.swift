import SwiftUI
import SwiftData

// MARK: - Equipment Selection View (Full Screen)
struct EquipmentSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    let equipment: [Equipment]
    @Binding var selectedEquipment: Set<Equipment>

    private var equipmentByCategory: [EquipmentCategory: [Equipment]] {
        Dictionary(grouping: equipment, by: { $0.category })
    }

    var body: some View {
        AppBackgroundView {
            NavigationStack {
                VStack {
                    if equipment.isEmpty {
                        ContentUnavailableView {
                            Label("Nessun attrezzo disponibile", systemImage: "dumbbell")
                        } description: {
                            Text("Inizializza prima la libreria attrezzi")
                        }
                        .padding()
                    } else {
                        List {
                            ForEach(EquipmentCategory.allCases, id: \.self) { category in
                                if let equipmentInCategory = equipmentByCategory[category], !equipmentInCategory.isEmpty {
                                    Section {
                                        ForEach(equipmentInCategory) { item in
                                            Button {
                                                toggleEquipment(item)
                                            } label: {
                                                HStack {
                                                    Text(item.name)
                                                        .foregroundStyle(.primary)
                                                    Spacer()
                                                    if selectedEquipment.contains(item) {
                                                        Image(systemName: "checkmark.circle.fill")
                                                            .foregroundStyle(.blue)
                                                    } else {
                                                        Image(systemName: "circle")
                                                            .foregroundStyle(.gray.opacity(0.3))
                                                    }
                                                }
                                            }
                                        }
                                    } header: {
                                        Label(category.rawValue, systemImage: category.icon)
                                    }
                                }
                            }
                        }
                        .listStyle(.insetGrouped)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                    }
                }
                .navigationTitle("Attrezzi")
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
    }

    private func toggleEquipment(_ item: Equipment) {
        if selectedEquipment.contains(item) {
            selectedEquipment.remove(item)
        } else {
            selectedEquipment.insert(item)
        }
    }
}
