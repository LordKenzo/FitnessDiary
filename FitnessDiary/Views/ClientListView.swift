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
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var showingAddClient = false
    @State private var selectedClient: Client?
    @State private var searchText = ""
    @State private var clientToDelete: Client?
    @State private var showingDeleteConfirmation = false
    @State private var showingDeleteAllConfirmation = false
    @State private var clientForWorkoutCards: Client?

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
                    Label(L("clients.no.clients"), systemImage: "person.3")
                } description: {
                    Text(L("clients.no.clients.description"))
                } actions: {
                    Button(L("clients.add")) {
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
                        .swipeActions(edge: .leading) {
                            Button {
                                clientForWorkoutCards = client
                            } label: {
                                Label(L("clients.workouts"), systemImage: "list.bullet.clipboard")
                            }
                            .tint(.blue)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                clientToDelete = client
                                showingDeleteConfirmation = true
                            } label: {
                                Label(L("confirm.delete"), systemImage: "trash")
                            }
                        }
                }
            }
        }
        .searchable(text: $searchText, prompt: L("clients.search"))
        .navigationTitle(L("clients.title"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingAddClient = true
                    } label: {
                        Label(L("clients.add"), systemImage: "plus")
                    }

                    if !clients.isEmpty {
                        Divider()
                        Button(role: .destructive) {
                            showingDeleteAllConfirmation = true
                        } label: {
                            Label(L("clients.delete.all"), systemImage: "trash")
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
        .sheet(item: $clientForWorkoutCards) { client in
            NavigationStack {
                ClientWorkoutCardsView(client: client)
            }
        }
        .alert(L("clients.delete.title"), isPresented: $showingDeleteConfirmation, presenting: clientToDelete) { client in
            Button(L("confirm.cancel"), role: .cancel) {
                clientToDelete = nil
            }
            Button(L("confirm.delete"), role: .destructive) {
                deleteClient(client)
            }
        } message: { client in
            Text(String(format: L("clients.delete.confirm.message"), client.fullName))
        }
        .alert(L("clients.delete.all.confirm"), isPresented: $showingDeleteAllConfirmation) {
            Button(L("confirm.cancel"), role: .cancel) { }
            Button(L("clients.delete.all"), role: .destructive) {
                deleteAllClients()
            }
        } message: {
            Text(String(format: L("clients.delete.all.confirm.message"), clients.count))
        }
    }

    private func deleteClient(_ client: Client) {
        modelContext.delete(client)
        clientToDelete = nil
    }

    private func deleteAllClients() {
        for client in clients {
            modelContext.delete(client)
        }
    }
}

struct ClientRow: View {
    let client: Client
    @ObservedObject private var localizationManager = LocalizationManager.shared

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
                        Label("\(age) \(L("profile.years"))", systemImage: "calendar")
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
    @ObservedObject private var localizationManager = LocalizationManager.shared

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
                Section(L("clients.form.required")) {
                    TextField(L("clients.first.name"), text: $firstName)
                    TextField(L("clients.last.name"), text: $lastName)
                }

                Section(L("profile.photo")) {
                    ClientPhotoPickerRow(
                        title: L("clients.form.photo.label"),
                        item: $photoItem,
                        photoData: $photoData
                    )
                }

                Section(L("clients.form.optional")) {
                    HStack {
                        Text(L("profile.age"))
                        Spacer()
                        TextField(L("profile.years"), value: $age, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }

                    Picker(L("profile.gender"), selection: $selectedGender) {
                        Text(L("clients.form.gender.not.specified")).tag(nil as Gender?)
                        ForEach([Gender.male, Gender.female, Gender.other], id: \.self) { gender in
                            Label(gender.rawValue, systemImage: gender.icon)
                                .tag(gender as Gender?)
                        }
                    }

                    HStack {
                        Text(L("profile.weight"))
                        Spacer()
                        TextField(L("unit.kg"), value: $weight, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }

                    HStack {
                        Text(L("profile.height"))
                        Spacer()
                        TextField("cm", value: $height, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }

                    TextField(L("clients.form.gym"), text: $gym)
                }

                Section(L("clients.form.medical.history")) {
                    TextEditor(text: $medicalHistory)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle(L("clients.new"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("confirm.cancel")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(L("confirm.save")) {
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
    @ObservedObject private var localizationManager = LocalizationManager.shared

    @Bindable var client: Client

    // Photo picker
    @State private var photoItem: PhotosPickerItem?
    @State private var showingFullscreen = false

    var body: some View {
        NavigationStack {
            Form {
                requiredDataSection
                photoSection
                optionalDataSection
                medicalHistorySection
                oneRepMaxSection
                workoutCardsSection
                deleteSection
            }
            .navigationTitle(L("clients.edit"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                doneButton
            }
            .fullScreenCover(isPresented: $showingFullscreen) {
                if let data = client.profileImageData {
                    FullscreenPhotoView(imageData: data)
                }
            }
        }
    }

    // MARK: - View Components

    private var requiredDataSection: some View {
        Section(L("clients.form.required")) {
            TextField(L("clients.first.name"), text: $client.firstName)
            TextField(L("clients.last.name"), text: $client.lastName)
        }
    }

    private var photoSection: some View {
        Section(L("profile.photo")) {
            ClientPhotoPickerRow(
                title: L("clients.form.photo.label"),
                item: $photoItem,
                photoData: $client.profileImageData
            )
        }
    }

    private var optionalDataSection: some View {
        Section(L("clients.form.optional")) {
            HStack {
                Text(L("profile.age"))
                Spacer()
                TextField(L("profile.years"), value: $client.age, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 100)
            }

            Picker(L("profile.gender"), selection: $client.gender) {
                Text(L("clients.form.gender.not.specified")).tag(nil as Gender?)
                ForEach([Gender.male, Gender.female, Gender.other], id: \.self) { gender in
                    Label(gender.rawValue, systemImage: gender.icon)
                        .tag(gender as Gender?)
                }
            }

            HStack {
                Text(L("profile.weight"))
                Spacer()
                TextField(L("unit.kg"), value: $client.weight, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 100)
            }

            HStack {
                Text(L("profile.height"))
                Spacer()
                TextField("cm", value: $client.height, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 100)
            }

            TextField(L("clients.form.gym"), text: Binding(
                get: { client.gym ?? "" },
                set: { client.gym = $0.isEmpty ? nil : $0 }
            ))
        }
    }

    private var medicalHistorySection: some View {
        Section(L("clients.form.medical.history")) {
            TextEditor(text: Binding(
                get: { client.medicalHistory ?? "" },
                set: { client.medicalHistory = $0.isEmpty ? nil : $0 }
            ))
            .frame(minHeight: 100)
        }
    }

    private var oneRepMaxSection: some View {
        Section(L("profile.one.rep.max")) {
            NavigationLink {
                OneRepMaxView(records: $client.oneRepMaxRecords)
            } label: {
                HStack {
                    Label(L("profile.manage.maxes"), systemImage: "figure.strengthtraining.traditional")
                    Spacer()
                    Text("\(client.oneRepMaxRecords.count)/5")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
        }
    }

    private var workoutCardsSection: some View {
        Section(L("clients.assigned.workouts")) {
            NavigationLink {
                ClientWorkoutCardsView(client: client)
            } label: {
                Label(L("clients.view.workouts"), systemImage: "list.bullet.clipboard")
            }
        }
    }

    private var deleteSection: some View {
        Section {
            Button(L("clients.delete.title"), role: .destructive) {
                deleteClient()
            }
        }
    }

    private var doneButton: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button(L("common.done")) {
                dismiss()
            }
            .disabled(!isFormValid)
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
@MainActor
struct ClientPhotoPickerRow: View {
    let title: String
    @Binding var item: PhotosPickerItem?
    @Binding var photoData: Data?
    @ObservedObject private var localizationManager = LocalizationManager.shared

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
                            Label(L("confirm.delete"), systemImage: "trash")
                        }
                    }
            } else {
                PhotosPicker(selection: $item, matching: .images) {
                    Label(L("common.select"), systemImage: "photo")
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
