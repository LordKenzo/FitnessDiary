//
//  WeekdaySelectionView.swift
//  FittyPal
//
//  Created by Claude on 20/11/2025.
//

import SwiftUI

struct WeekdaySelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedDays: [Weekday]
    let requiredCount: Int

    @State private var localSelection: Set<Weekday>

    init(selectedDays: Binding<[Weekday]>, requiredCount: Int) {
        self._selectedDays = selectedDays
        self.requiredCount = requiredCount
        _localSelection = State(initialValue: Set(selectedDays.wrappedValue))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header con info
                if localSelection.count != requiredCount {
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text("Seleziona \(requiredCount) giorni")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(localSelection.count)/\(requiredCount)")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundStyle(localSelection.count == requiredCount ? .green : .orange)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.orange.opacity(0.1))
                    }
                }

                // Lista giorni
                List {
                    Section {
                        ForEach(Weekday.orderedFromMonday) { day in
                            Button {
                                toggleDay(day)
                            } label: {
                                HStack(spacing: 16) {
                                    // Cerchio colorato per il giorno
                                    ZStack {
                                        Circle()
                                            .fill(localSelection.contains(day) ? Color.blue : Color.gray.opacity(0.2))
                                            .frame(width: 44, height: 44)

                                        Text(day.symbol)
                                            .font(.headline)
                                            .fontWeight(.bold)
                                            .foregroundStyle(localSelection.contains(day) ? .white : .secondary)
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(day.fullName)
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundStyle(.primary)

                                        Text(day.shortName)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    if localSelection.contains(day) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.title3)
                                            .foregroundStyle(.blue)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    } header: {
                        Text("Giorni della Settimana")
                    } footer: {
                        Text("Questi saranno i giorni fissi di allenamento per tutto il piano. Scegli \(requiredCount) giorni in base alla tua frequenza settimanale.")
                    }

                    // Sezione preset suggeriti
                    if !presetSuggestions.isEmpty {
                        Section {
                            ForEach(presetSuggestions, id: \.name) { preset in
                                Button {
                                    localSelection = Set(preset.days)
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(preset.name)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundStyle(.primary)

                                            Text(preset.days.map { $0.shortName }.joined(separator: ", "))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }

                                        Spacer()

                                        Image(systemName: "arrow.right.circle")
                                            .foregroundStyle(.blue)
                                    }
                                }
                            }
                        } header: {
                            Text("Preset Consigliati")
                        }
                    }
                }
                .glassScrollBackground()
            }
            .navigationTitle("Giorni Allenamento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Conferma") {
                        saveDays()
                    }
                    .disabled(localSelection.count != requiredCount)
                    .fontWeight(.semibold)
                }
            }
            .appScreenBackground()
        }
    }

    private func toggleDay(_ day: Weekday) {
        if localSelection.contains(day) {
            localSelection.remove(day)
        } else {
            // Se abbiamo già selezionato il numero richiesto, non permettere di aggiungere
            if localSelection.count < requiredCount {
                localSelection.insert(day)
            }
        }
    }

    private func saveDays() {
        selectedDays = Array(localSelection).sorted { $0.rawValue < $1.rawValue }
        dismiss()
    }

    // MARK: - Preset Suggestions

    private struct DayPreset {
        let name: String
        let days: [Weekday]
    }

    private var presetSuggestions: [DayPreset] {
        switch requiredCount {
        case 2:
            return [
                DayPreset(name: "Lun-Gio (Upper/Lower)", days: [.monday, .thursday]),
                DayPreset(name: "Mar-Ven", days: [.tuesday, .friday]),
                DayPreset(name: "Mer-Sab", days: [.wednesday, .saturday])
            ]
        case 3:
            return [
                DayPreset(name: "Lun-Mer-Ven (Classico)", days: [.monday, .wednesday, .friday]),
                DayPreset(name: "Mar-Gio-Sab", days: [.tuesday, .thursday, .saturday]),
                DayPreset(name: "Lun-Gio-Sab", days: [.monday, .thursday, .saturday])
            ]
        case 4:
            return [
                DayPreset(name: "Lun-Mar-Gio-Ven", days: [.monday, .tuesday, .thursday, .friday]),
                DayPreset(name: "Lun-Mer-Ven-Sab", days: [.monday, .wednesday, .friday, .saturday]),
                DayPreset(name: "Mar-Mer-Ven-Sab", days: [.tuesday, .wednesday, .friday, .saturday])
            ]
        case 5:
            return [
                DayPreset(name: "Lun-Mar-Mer-Gio-Ven (Settimana)", days: [.monday, .tuesday, .wednesday, .thursday, .friday]),
                DayPreset(name: "Lun-Mar-Gio-Ven-Sab", days: [.monday, .tuesday, .thursday, .friday, .saturday])
            ]
        case 6:
            return [
                DayPreset(name: "Lun-Mar-Mer-Gio-Ven-Sab (PPL 2x)", days: [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday])
            ]
        default:
            return []
        }
    }
}

#Preview {
    WeekdaySelectionView(selectedDays: .constant([.monday, .wednesday, .friday]), requiredCount: 3)
}
