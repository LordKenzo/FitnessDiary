import SwiftUI
import SwiftData
import PhotosUI

struct ProfileView: View {
    @Query private var profiles: [UserProfile]
    @State private var showingSetup = false
    
    private var profile: UserProfile? {
        profiles.first
    }
    
    var body: some View {
        NavigationStack {
            if let profile = profile {
                ProfileDetailView(profile: profile)
            } else {
                ContentUnavailableView {
                    Label("Nessun Profilo", systemImage: "person.circle")
                } description: {
                    Text("Crea il tuo profilo per iniziare")
                } actions: {
                    Button("Crea Profilo") {
                        showingSetup = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .sheet(isPresented: $showingSetup) {
            ProfileSetupView()
        }
        .onAppear {
            if profile == nil {
                showingSetup = true
            }
        }
    }
}

struct ProfileDetailView: View {
    @Bindable var profile: UserProfile
    @State private var showingEdit = false
    @State private var showingZonesEditor = false
    
    var body: some View {
        List {
            // Foto e Info Base
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        if let image = profile.profileImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 100, height: 100)
                                .foregroundStyle(.gray)
                        }
                        
                        Text(profile.name)
                            .font(.title2)
                            .bold()
                    }
                    Spacer()
                }
            }
            .listRowBackground(Color.clear)
            
            Section("Dati Fisici") {
                LabeledContent("Sesso", value: profile.gender.rawValue)
                LabeledContent("Età", value: "\(profile.age) anni")
                LabeledContent("Peso", value: String(format: "%.1f kg", profile.weight))
                LabeledContent("Altezza", value: String(format: "%.0f cm", profile.height))
                LabeledContent("BMI", value: String(format: "%.1f", calculateBMI()))
            }

            Section("Massimali 1RM") {
                NavigationLink {
                    OneRepMaxView(oneRepMaxRecords: $profile.oneRepMaxRecords)
                } label: {
                    HStack {
                        Label("Gestisci Massimali", systemImage: "figure.strengthtraining.traditional")
                        Spacer()
                        Text("\(profile.oneRepMaxRecords.count)/5")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                }
            }

            Section {
                LabeledContent("FC Massima", value: "\(profile.maxHeartRate) bpm")
                LabeledContent("FC Calcolata", value: "\(220 - profile.age) bpm")
                    .foregroundStyle(.secondary)
            } header: {
                Text("Frequenza Cardiaca")
            } footer: {
                Text("FC massima personalizzata o calcolata con formula 220 - età")
            }
            
            Section {
                ForEach(HeartRateZone.allCases, id: \.rawValue) { zone in
                    HStack {
                        Circle()
                            .fill(zone.color)
                            .frame(width: 12, height: 12)
                        Text(zone.name)
                        Spacer()
                        Text(zoneRange(for: zone))
                            .foregroundStyle(.secondary)
                    }
                }
                
                Button {
                    showingZonesEditor = true
                } label: {
                    Label("Personalizza Zone Cardio", systemImage: "slider.horizontal.3")
                }
            } header: {
                Text("Zone Cardio")
            }
        }
        .navigationTitle("Profilo")
        .toolbar {
            Button("Modifica") {
                showingEdit = true
            }
        }
        .sheet(isPresented: $showingEdit) {
            ProfileEditView(profile: profile)
        }
        .sheet(isPresented: $showingZonesEditor) {
            HeartRateZonesEditorView(profile: profile)
        }
    }
    
    /// Computes the body mass index (BMI) for the current profile.
    /// - Returns: The BMI value computed as weight in kilograms divided by height in meters squared.
    private func calculateBMI() -> Double {
        let heightInMeters = profile.height / 100
        guard heightInMeters > 0 else { return 0 }
        return profile.weight / (heightInMeters * heightInMeters)
    }
    
    /// Formats the BPM range string for a given heart rate zone using the current profile's zone thresholds.
    /// - Parameters:
    ///   - zone: The heart rate zone to format.
    /// - Returns: A human-readable BPM range for the zone (e.g., "< 100 bpm", "100-120 bpm", "> 160 bpm").
    private func zoneRange(for zone: HeartRateZone) -> String {
        switch zone {
        case .zone1:
            return "0 - \(profile.zone1Max) bpm"
        case .zone2:
            return "\(profile.zone1Max + 1) - \(profile.zone2Max) bpm"
        case .zone3:
            return "\(profile.zone2Max + 1) - \(profile.zone3Max) bpm"
        case .zone4:
            return "\(profile.zone3Max + 1) - \(profile.zone4Max) bpm"
        case .zone5:
            return "\(profile.zone4Max + 1) - \(profile.zone5Max) bpm"
        }
    }
}

struct ProfileEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var healthKitManager = HealthKitManager()
    
    @Bindable var profile: UserProfile
    
    @State private var name: String
    @State private var age: Int
    @State private var gender: Gender
    @State private var weight: Double
    @State private var height: Double
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImage: UIImage?
    @State private var isLoadingHealthData = false
    
    init(profile: UserProfile) {
        self.profile = profile
        _name = State(initialValue: profile.name)
        _age = State(initialValue: profile.age)
        _gender = State(initialValue: profile.gender)
        _weight = State(initialValue: profile.weight)
        _height = State(initialValue: profile.height)
        _profileImage = State(initialValue: profile.profileImage)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Sezione Foto
                Section("Foto Profilo") {
                    HStack {
                        Spacer()
                        if let image = profileImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 120, height: 120)
                                .foregroundStyle(.gray)
                        }
                        Spacer()
                    }
                    
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label("Cambia Foto", systemImage: "photo")
                    }
                    
                    if profileImage != nil {
                        Button(role: .destructive) {
                            profileImage = nil
                        } label: {
                            Label("Rimuovi Foto", systemImage: "trash")
                        }
                    }
                }
                
                // Sezione Dati Personali
                Section("Dati Personali") {
                    TextField("Nome", text: $name)
                    
                    Picker("Sesso", selection: $gender) {
                        ForEach(Gender.allCases, id: \.self) { gender in
                            Text(gender.rawValue).tag(gender)
                        }
                    }
                    
                    HStack {
                        Text("Età")
                        Spacer()
                        TextField("Età", value: $age, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text("anni")
                    }
                    
                    HStack {
                        Text("Peso")
                        Spacer()
                        TextField("Peso", value: $weight, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text("kg")
                    }
                    
                    HStack {
                        Text("Altezza")
                        Spacer()
                        TextField("Altezza", value: $height, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text("cm")
                    }
                    
                    Button {
                        Task {
                            await importFromHealthKit()
                        }
                    } label: {
                        Label("Aggiorna da Apple Health", systemImage: "arrow.clockwise")
                    }
                    .disabled(isLoadingHealthData)
                }
            }
            .navigationTitle("Modifica Profilo")
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
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onChange(of: selectedPhoto) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        profileImage = image
                    }
                }
            }
        }
    }
    
    private func importFromHealthKit() async {
        isLoadingHealthData = true
        defer { isLoadingHealthData = false }
        
        do {
            try await healthKitManager.requestAuthorization()
            let data = try await healthKitManager.fetchUserData()
            
            if let weight = data.weight {
                self.weight = weight
            }
            if let height = data.height {
                self.height = height
            }
            if let age = data.age {
                self.age = age
            }
            if let gender = data.gender {
                self.gender = gender
            }
        } catch {
            print("Errore importazione HealthKit: \(error)")
        }
    }
    
    private func saveChanges() {
        profile.name = name
        profile.age = age
        profile.gender = gender
        profile.weight = weight
        profile.height = height
        profile.profileImage = profileImage
        
        // Aggiorna FC massima se l'età è cambiata e si usa quella calcolata
        let calculatedMaxHR = 220 - age
        if profile.maxHeartRate == (220 - profile.age) {
            profile.updateHeartRateZones(maxHR: calculatedMaxHR)
        }
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: UserProfile.self, inMemory: true)
}