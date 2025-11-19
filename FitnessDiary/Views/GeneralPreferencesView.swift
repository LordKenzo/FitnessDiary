import SwiftUI
import AVFoundation

struct GeneralPreferencesView: View {
    @AppStorage("debugWorkoutLogEnabled") private var debugWorkoutLogEnabled = false
    @AppStorage("workoutCountdownSeconds") private var workoutCountdownSeconds = 10
    @AppStorage("cloneLoadEnabled") private var cloneLoadEnabled = true
    @AppStorage("appColorTheme") private var appColorThemeRaw = AppColorTheme.vibrant.rawValue
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                generalPreferencesCard
                AudioPreferencesCard()
                    .dashboardCardStyle()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .navigationTitle(L("preferences.title"))
        .navigationBarTitleDisplayMode(.inline)
        .appScreenBackground()
    }

    private var generalPreferencesCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(L("preferences.section.general").uppercased())
                .font(.caption.weight(.semibold))
                .tracking(0.6)
                .foregroundStyle(AppTheme.subtleText(for: colorScheme))

            VStack(alignment: .leading, spacing: 8) {
                Text(L("preferences.language"))
                    .font(.subheadline.weight(.semibold))

                Picker("", selection: Binding(
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
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(L("preferences.theme.title"))
                    .font(.subheadline.weight(.semibold))

                Picker("", selection: Binding(
                    get: { appColorTheme },
                    set: { appColorTheme = $0 }
                )) {
                    ForEach(AppColorTheme.allCases) { theme in
                        Text(localized: theme.localizationKey)
                            .tag(theme)
                    }
                }
                .pickerStyle(.segmented)
            }

            Toggle(L("preferences.debug.log"), isOn: $debugWorkoutLogEnabled)
                .tint(.blue)

            Toggle(L("preferences.clone.load"), isOn: $cloneLoadEnabled)
                .tint(.blue)
                .font(.subheadline)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(localized: "preferences.countdown")
                    Spacer()
                    Text(String(format: L("preferences.countdown.seconds"), workoutCountdownSeconds))
                        .foregroundStyle(AppTheme.subtleText(for: colorScheme))
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
         
        }
        .dashboardCardStyle()
}



    private var appColorTheme: AppColorTheme {
        get { AppColorTheme(rawValue: appColorThemeRaw) ?? .vibrant }
        nonmutating set { appColorThemeRaw = newValue.rawValue }
    }
}

private struct AudioPreferencesCard: View {
    private typealias TimerSound = WorkoutExecutionViewModel.TimerSound

    @AppStorage(TimerPreferenceKeys.soundEnabled) private var isTimerSoundEnabled = true
    @AppStorage(TimerPreferenceKeys.selectedSound) private var selectedSoundRaw = TimerSound.classic.rawValue
    @AppStorage(TimerPreferenceKeys.soundVolume) private var soundVolume = 0.8

    @State private var previewPlayer: AVAudioPlayer?
    @State private var pendingVolumePreview: DispatchWorkItem?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L("preferences.section.audio").uppercased())
                .font(.caption.weight(.semibold))
                .tracking(0.6)
                .foregroundStyle(AppTheme.subtleText(for: colorScheme))

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
                        .foregroundStyle(AppTheme.subtleText(for: colorScheme))
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity)
                .background(
                    AppTheme.chipBackground(for: colorScheme),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
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
                        .foregroundStyle(AppTheme.subtleText(for: colorScheme))
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
        .onDisappear {
            stopPreview()
        }
    }

    private var selectedSound: TimerSound {
        get { TimerSound(rawValue: selectedSoundRaw) ?? .classic }
        nonmutating set { selectedSoundRaw = newValue.rawValue }
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
            print("Failed to play preview: \(error)")
        }
    }
}
