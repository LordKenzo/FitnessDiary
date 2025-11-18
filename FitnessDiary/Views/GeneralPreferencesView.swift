import SwiftUI
import AVFoundation

struct GeneralPreferencesView: View {
    @AppStorage("debugWorkoutLogEnabled") private var debugWorkoutLogEnabled = false
    @AppStorage("workoutCountdownSeconds") private var workoutCountdownSeconds = 10
    @AppStorage("cloneLoadEnabled") private var cloneLoadEnabled = true
    @ObservedObject private var localizationManager = LocalizationManager.shared

    var body: some View {
        Form {
            Section(L("preferences.section.general")) {
                // Language Picker
                Picker(L("preferences.language"), selection: Binding(
                    get: { localizationManager.currentLanguage },
                    set: { newLanguage in
                        localizationManager.setLanguage(newLanguage)
                    }
                )) {
                    ForEach(AppLanguage.allCases) { language in
                        HStack {
                            Text(language.flag)
                            Text(language.displayName)
                        }
                        .tag(language)
                    }
                }
                .pickerStyle(.menu)

                Toggle(L("preferences.debug.log"), isOn: $debugWorkoutLogEnabled)

                Toggle(L("preferences.clone.load"), isOn: $cloneLoadEnabled)
                    .tint(.blue)
                    .font(.subheadline)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(localized: "preferences.countdown")
                        Spacer()
                        Text(String(format: L("preferences.countdown.seconds"), workoutCountdownSeconds))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }

                    Slider(
                        value: Binding(
                            get: { Double(workoutCountdownSeconds) },
                            set: { workoutCountdownSeconds = Int($0) }
                        ),
                        in: 0...120,
                        step: 1
                    )
                }

                Text(localized: "preferences.made.by")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 4)
            }

            Section(L("preferences.section.audio")) {
                AudioPreferencesCard()
            }
        }
        .navigationTitle(L("preferences.title"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct AudioPreferencesCard: View {
    private typealias TimerSound = WorkoutExecutionViewModel.TimerSound

    @AppStorage(TimerPreferenceKeys.soundEnabled) private var isTimerSoundEnabled = true
    @AppStorage(TimerPreferenceKeys.selectedSound) private var selectedSoundRaw = TimerSound.classic.rawValue
    @AppStorage(TimerPreferenceKeys.soundVolume) private var soundVolume = 0.8

    @State private var previewPlayer: AVAudioPlayer?
    @State private var pendingVolumePreview: DispatchWorkItem?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(L("timer.sound.title"), systemImage: "speaker.wave.2.fill")
                .font(.headline)

            Toggle(L("preferences.audio.toggle"), isOn: $isTimerSoundEnabled)
                .tint(.blue)
                .onChange(of: isTimerSoundEnabled) { _, newValue in
                    handleSoundToggleChange(newValue)
                }

            Divider()

            Menu {
                ForEach(TimerSound.allCases) { sound in
                    Button {
                        handleSoundSelection(sound)
                    } label: {
                        Label {
                            Text(localized: sound.localizationKey)
                        } icon: {
                            Image(systemName: sound == selectedSound ? "checkmark" : sound.iconName)
                        }
                    }
                }
            } label: {
                HStack {
                    Label {
                        Text(localized: selectedSound.localizationKey)
                    } icon: {
                        Image(systemName: "music.note.list")
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled(!isTimerSoundEnabled)
            .opacity(isTimerSoundEnabled ? 1 : 0.5)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(localized: "timer.sound.volume")
                    Spacer()
                    Text(String(format: "%.0f%%", soundVolume * 100))
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                Slider(
                    value: Binding(
                        get: { soundVolume },
                        set: { newValue in
                            soundVolume = newValue
                            scheduleVolumePreview()
                        }
                    ),
                    in: 0...1
                )
                .disabled(!isTimerSoundEnabled || selectedSound == .mute)
            }
            .opacity(isTimerSoundEnabled ? 1 : 0.5)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var selectedSound: TimerSound {
        get { TimerSound(rawValue: selectedSoundRaw) ?? .classic }
        set { selectedSoundRaw = newValue.rawValue }
    }

    private func handleSoundSelection(_ sound: TimerSound) {
        selectedSound = sound
        playPreview(for: sound)
    }

    private func handleSoundToggleChange(_ isEnabled: Bool) {
        if isEnabled {
            playPreview()
        } else {
            stopPreview()
        }
    }

    private func scheduleVolumePreview() {
        guard isTimerSoundEnabled else { return }
        pendingVolumePreview?.cancel()
        let workItem = DispatchWorkItem {
            pendingVolumePreview = nil
            playPreview()
        }
        pendingVolumePreview = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: workItem)
    }

    private func stopPreview() {
        pendingVolumePreview?.cancel()
        pendingVolumePreview = nil
        previewPlayer?.stop()
        previewPlayer = nil
    }

    private func playPreview(for sound: TimerSound? = nil) {
        guard isTimerSoundEnabled else { return }
        let toneSound = sound ?? selectedSound
        guard let tone = toneSound.previewTone else { return }
        let toneData = TimerToneGenerator.makeToneData(frequency: tone.frequency, duration: tone.duration)
        guard !toneData.isEmpty else { return }

        do {
            previewPlayer = try AVAudioPlayer(data: toneData)
            previewPlayer?.volume = Float(soundVolume)
            previewPlayer?.prepareToPlay()
            previewPlayer?.play()
        } catch {
            print("Failed to play preview tone", error)
        }
    }
}

#Preview {
    NavigationStack {
        GeneralPreferencesView()
    }
}
