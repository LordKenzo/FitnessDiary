//
//  CustomMethodsListView.swift
//  FittyPal
//
//  Created by Claude on 20/11/2025.
//

import SwiftUI
import SwiftData

struct CustomMethodsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CustomTrainingMethod.name) private var customMethods: [CustomTrainingMethod]
    @State private var showingAddMethod = false
    @State private var selectedMethod: CustomTrainingMethod?
    @State private var methodToDelete: CustomTrainingMethod?
    @State private var showingDeleteAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                if customMethods.isEmpty {
                    GlassEmptyStateCard(
                        systemImage: "bolt.circle.fill",
                        title: "Nessun Metodo Custom",
                        description: "Crea il tuo primo metodo di allenamento personalizzato per definire serie con percentuali di carico e pause specifiche per ogni ripetizione."
                    ) {
                        Button("Crea Metodo Custom") {
                            showingAddMethod = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    GlassSectionCard(title: "I Tuoi Metodi", iconName: "bolt.circle.fill") {
                        ForEach(customMethods) { method in
                            GlassListRow(
                                title: method.name,
                                subtitle: method.methodDescription,
                                iconName: "bolt.fill"
                            ) {
                                menuButton(for: method)
                            }
                            .onTapGesture {
                                selectedMethod = method
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .navigationTitle("Metodi Custom")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddMethod = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddMethod) {
            NavigationStack {
                EditCustomMethodView()
            }
        }
        .sheet(item: $selectedMethod) { method in
            NavigationStack {
                EditCustomMethodView(method: method)
            }
        }
        .alert("Elimina Metodo", isPresented: $showingDeleteAlert, presenting: methodToDelete) { method in
            Button("Elimina", role: .destructive) {
                deleteMethod(method)
            }
            Button("Annulla", role: .cancel) { }
        } message: { method in
            Text("Sei sicuro di voler eliminare il metodo '\(method.name)'? Questa azione non può essere annullata.")
        }
    }

    private func menuButton(for method: CustomTrainingMethod) -> some View {
        Menu {
            Button {
                selectedMethod = method
            } label: {
                Label("Modifica", systemImage: "pencil")
            }

            Divider()

            Button(role: .destructive) {
                methodToDelete = method
                showingDeleteAlert = true
            } label: {
                Label("Elimina", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis")
                .foregroundColor(.secondary)
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
    }

    private func deleteMethod(_ method: CustomTrainingMethod) {
        modelContext.delete(method)
    }
}

#Preview {
    NavigationStack {
        CustomMethodsListView()
            .modelContainer(for: [CustomTrainingMethod.self], inMemory: true)
    }
}
