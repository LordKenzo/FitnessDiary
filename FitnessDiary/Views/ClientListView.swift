//
//  ClientListView.swift
//  FitnessDiary
//
//  Created by Claude on 16/11/2025.
//

import SwiftUI
import SwiftData
import PhotosUI

struct ClientListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Client.lastName), SortDescriptor(\Client.firstName)]) private var clients: [Client]
    @State private var showingAddClient = false
    @State private var selectedClient: Client?
    @State private var searchText = ""

    private var filteredClients: [Client] {
        if searchText.isEmpty {
            return clients
        } else {
            return clients.filter { client in
                client.firstName.localizedCaseInsensitiveContains(searchText) ||
                client.lastName.localizedCaseInsensitiveContains(searchText) ||
                client.fullName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        List {
            if clients.isEmpty {
                ContentUnavailableView {
                    Label("Nessun Cliente", systemImage: "person.3")
                } description: {
                    Text("Aggiungi il tuo primo cliente per iniziare")
                } actions: {
                    Button("Aggiungi Cliente") {
                        showingAddClient = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                ForEach(filteredClients) { client in
                    ClientRow(client: client)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedClient = client
                        }
                }
                .onDelete(perform: deleteClients)
            }
        }
        .searchable(text: $searchText, prompt: "Cerca cliente")
        .navigationTitle("Clienti")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingAddClient = true
                    } label: {
                        Label("Aggiungi Cliente", systemImage: "plus")
                    }

                    if !clients.isEmpty {
                        Divider()
                        Button(role: .destructive) {
                            deleteAllClients()
                        } label: {
                            Label("Elimina Tutti", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingAddClient) {
            AddClientView()
        }
        .sheet(item: $selectedClient) { client in
            EditClientView(client: client)
        }
    }

    private func deleteClients(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredClients[index])
        }
    }

    private func deleteAllClients() {
        for client in clients {
            modelContext.delete(client)
        }
    }
}

struct ClientRow: View {
    let client: Client

    var body: some View {
        HStack(spacing: 12) {
            // Foto profilo
            Group {
                if let image = client.profileImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(client.fullName)
                    .font(.headline)

                HStack(spacing: 8) {
                    if let age = client.age {
                        Label("\(age) anni", systemImage: "calendar")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let gender = client.gender {
                        Label(gender.rawValue, systemImage: gender.icon)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let gym = client.gym {
                        Label(gym, systemImage: "building.2")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct AddClientView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var age: Int?
    @State private var selectedGender: Gender?
    @State private var weight: Double?
    @State private var height: Double?
    @State private var medicalHistory = ""
    @State private var gym = ""

    // Photo picker
    @State private var photoItem: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var showingFullscreen = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Dati Obbligatori") {
                    TextField("Nome", text: $firstName)
                    TextField("Cognome", text: $lastName)
                }

                Section("Foto Profilo") {
                    ClientPhotoPickerRow(
                        title: "Foto",
                        item: $photoItem,
                        photoData: $photoData
                    )
                }

                Section("Dati Facoltativi") {
                    HStack {
                        Text("Età")
                        Spacer()
                        TextField("Anni", value: $age, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }

                    Picker("Sesso", selection: $selectedGender) {
                        Text("Non specificato").tag(nil as Gender?)
                        ForEach([Gender.male, Gender.female, Gender.other], id: \.self) { gender in
                            Label(gender.rawValue, systemImage: gender.icon)
                                .tag(gender as Gender?)
                        }
                    }

                    HStack {
                        Text("Peso (kg)")
                        Spacer()
                        TextField("kg", value: $weight, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }

                    HStack {
                        Text("Altezza (cm)")
                        Spacer()
                        TextField("cm", value: $height, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }

                    TextField("Palestra", text: $gym)
                }

                Section("Anamnesi") {
                    TextEditor(text: $medicalHistory)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Nuovo Cliente")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        saveClient()
                    }
                    .disabled(!isFormValid)
                }
            }
            .fullScreenCover(isPresented: $showingFullscreen) {
                if let data = photoData {
                    FullscreenPhotoView(imageData: data)
                }
            }
        }
    }

    private var isFormValid: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func saveClient() {
        let client = Client(
            firstName: firstName.trimmingCharacters(in: .whitespaces),
            lastName: lastName.trimmingCharacters(in: .whitespaces),
            profileImageData: photoData,
            age: age,
            gender: selectedGender,
            weight: weight,
            height: height,
            medicalHistory: medicalHistory.isEmpty ? nil : medicalHistory,
            gym: gym.isEmpty ? nil : gym
        )
        modelContext.insert(client)
        dismiss()
    }
}

struct EditClientView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var client: Client

    // Photo picker
    @State private var photoItem: PhotosPickerItem?
    @State private var showingFullscreen = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Dati Obbligatori") {
                    TextField("Nome", text: $client.firstName)
                    TextField("Cognome", text: $client.lastName)
                }

                Section("Foto Profilo") {
                    ClientPhotoPickerRow(
                        title: "Foto",
                        item: $photoItem,
                        photoData: $client.profileImageData
                    )
                }

                Section("Dati Facoltativi") {
                    HStack {
                        Text("Età")
                        Spacer()
                        TextField("Anni", value: $client.age, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }

                    Picker("Sesso", selection: $client.gender) {
                        Text("Non specificato").tag(nil as Gender?)
                        ForEach([Gender.male, Gender.female, Gender.other], id: \.self) { gender in
                            Label(gender.rawValue, systemImage: gender.icon)
                                .tag(gender as Gender?)
                        }
                    }

                    HStack {
                        Text("Peso (kg)")
                        Spacer()
                        TextField("kg", value: $client.weight, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }

                    HStack {
                        Text("Altezza (cm)")
                        Spacer()
                        TextField("cm", value: $client.height, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }

                    TextField("Palestra", text: Binding(
                        get: { client.gym ?? "" },
                        set: { client.gym = $0.isEmpty ? nil : $0 }
                    ))
                }

                Section("Anamnesi") {
                    TextEditor(text: Binding(
                        get: { client.medicalHistory ?? "" },
                        set: { client.medicalHistory = $0.isEmpty ? nil : $0 }
                    ))
                    .frame(minHeight: 100)
                }

                Section {
                    Button("Elimina Cliente", role: .destructive) {
                        deleteClient()
                    }
                }
            }
            .navigationTitle("Modifica Cliente")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fatto") {
                        dismiss()
                    }
                    .disabled(!isFormValid)
                }
            }
            .fullScreenCover(isPresented: $showingFullscreen) {
                if let data = client.profileImageData {
                    FullscreenPhotoView(imageData: data)
                }
            }
        }
    }

    private var isFormValid: Bool {
        !client.firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !client.lastName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func deleteClient() {
        modelContext.delete(client)
        dismiss()
    }
}

// ClientPhotoPickerRow component (versione semplificata per singola foto)
struct ClientPhotoPickerRow: View {
    let title: String
    @Binding var item: PhotosPickerItem?
    @Binding var photoData: Data?

    @State private var showingFullscreen = false

    var body: some View {
        HStack {
            Text(title)

            Spacer()

            if let data = photoData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .onTapGesture {
                        showingFullscreen = true
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            photoData = nil
                            item = nil
                        } label: {
                            Label("Elimina", systemImage: "trash")
                        }
                    }
            } else {
                PhotosPicker(selection: $item, matching: .images) {
                    Label("Seleziona", systemImage: "photo")
                }
            }
        }
        .onChange(of: item) { _, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self) {
                    photoData = data
                }
            }
        }
        .fullScreenCover(isPresented: $showingFullscreen) {
            if let data = photoData {
                FullscreenPhotoView(imageData: data)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ClientListView()
    }
    .modelContainer(for: Client.self, inMemory: true)
}
