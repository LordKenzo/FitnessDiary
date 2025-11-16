import SwiftUI
import PhotosUI
import SwiftData

struct ProfileSetupView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var healthKitManager = HealthKitManager()
    
    @State private var name = ""
    @State private var age = 25
    @State private var gender: Gender = .other
    @State private var weight = 70.0
    @State private var height = 170.0
    @State private var maxHeartRate = 195
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImage: UIImage?
    @State private var showHealthKitImport = false
    @State private var isLoadingHealthData = false
    
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
                        Label("Scegli Foto", systemImage: "photo")
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
                        Label("Importa da Apple Health", systemImage: "heart.text.square.fill")
                    }
                    .disabled(isLoadingHealthData)
                }
                
                // Sezione Zone Cardio
                Section {
                    HStack {
                        Text("FC Massima")
                        Spacer()
                        TextField("FC Max", value: $maxHeartRate, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text("bpm")
                    }
                    
                    Text("Calcolata: \(220 - age) bpm")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Frequenza Cardiaca")
                } footer: {
                    Text("La FC massima viene calcolata automaticamente (220 - età), ma puoi personalizzarla")
                }
                
                Section("Zone Cardio") {
                    ForEach(HeartRateZone.allCases, id: \.rawValue) { zone in
                        HStack {
                            Circle()
                                .fill(zone.color)
                                .frame(width: 12, height: 12)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(zone.name)
                                    .font(.subheadline)
                                Text(zone.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(zoneRange(for: zone))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Profilo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        saveProfile()
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
    
    private func zoneRange(for zone: HeartRateZone) -> String {
        let profile = UserProfile(age: age, maxHeartRate: maxHeartRate)
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
                self.maxHeartRate = 220 - age
            }
            if let gender = data.gender {
                self.gender = gender
            }
        } catch {
            print("Errore importazione HealthKit: \(error)")
        }
    }
    
    private func saveProfile() {
        let profile = UserProfile(
            name: name,
            age: age,
            gender: gender,
            weight: weight,
            height: height,
            maxHeartRate: maxHeartRate
        )
        
        if let image = profileImage {
            profile.profileImage = image
        }
        
        modelContext.insert(profile)
        dismiss()
    }
}

#Preview {
    ProfileSetupView()
        .modelContainer(for: UserProfile.self, inMemory: true)
}
