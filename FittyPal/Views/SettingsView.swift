//
//  SettingsView.swift
//  FitnessDiary
//
//  Created by Lorenzo Franceschini on 16/11/25.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    let bluetoothManager: BluetoothHeartRateManager
    @Query private var profiles: [UserProfile]
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        NavigationStack {
            AppBackgroundView {
                ScrollView {
                    VStack(spacing: 24) {
                        SettingsSectionCard(title: L("settings.section.general")) {
                            SettingsNavigationRow(
                                title: L("settings.general.preferences"),
                                iconName: "slider.horizontal.3"
                            ) {
                                GeneralPreferencesView()
                            }
                            SettingsNavigationRow(
                                title: L("preferences.theme.title"),
                                iconName: "paintpalette"
                            ) {
                                ThemeSelectionView()
                            }
                        }
                        SettingsSectionCard(title: L("settings.section.account")) {
                            SettingsNavigationRow(
                                title: L("settings.profile"),
                                iconName: "person.circle"
                            ) {
                                ProfileView()
                            }
                        }
                        SettingsSectionCard(title: L("settings.section.clients")) {
                            SettingsNavigationRow(
                                title: L("settings.clients.management"),
                                iconName: "person.3"
                            ) {
                                ClientListView()
                            }
                        }
                        SettingsSectionCard(title: L("settings.section.monitoring")) {
                            SettingsNavigationRow(
                                title: L("settings.heart.rate"),
                                iconName: "heart.circle"
                            ) {
                                HeartRateMonitorView(bluetoothManager: bluetoothManager)
                            }
                            SettingsNavigationRow(
                                title: L("settings.strength.expressions"),
                                iconName: "bolt.fill"
                            ) {
                                StrengthExpressionsView()
                            }
                        }
                        SettingsSectionCard(title: L("settings.section.library")) {
                            SettingsNavigationRow(
                                title: L("settings.muscles"),
                                iconName: "figure.arms.open"
                            ) {
                                MuscleListView()
                            }
                            SettingsNavigationRow(
                                title: L("settings.equipment"),
                                iconName: "dumbbell"
                            ) {
                                EquipmentListView()
                            }
                            SettingsNavigationRow(
                                title: L("settings.exercises"),
                                iconName: "figure.strengthtraining.traditional"
                            ) {
                                ExerciseListView()
                            }
                            SettingsNavigationRow(
                                title: "Metodi Classici",
                                iconName: "book.fill"
                            ) {
                                ClassicMethodsLibraryView()
                            }
                            SettingsNavigationRow(
                                title: "Metodi Custom",
                                iconName: "bolt.circle.fill"
                            ) {
                                CustomMethodsListView()
                            }
                        }
                        SettingsSectionCard(title: L("settings.section.legal")) {
                            if let privacyURL = SupportResources.privacyPolicyURL {
                                Link(destination: privacyURL) {
                                    SettingsRow(title: L("settings.legal.privacy"), iconName: "lock.shield", showsDisclosure: false)
                                }
                            }
                            if let termsURL = SupportResources.termsOfUseURL {
                                Link(destination: termsURL) {
                                    SettingsRow(title: L("settings.legal.terms"), iconName: "doc.text", showsDisclosure: false)
                                }
                            }
                            if let supportURL = SupportResources.supportEmailURL {
                                Link(destination: supportURL) {
                                    SettingsRow(title: L("settings.legal.support"), iconName: "envelope", showsDisclosure: false)
                                }
                            }
                        }
                        
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                    VStack(spacing: 4) {
                        Text(versionText)
                            .font(.footnote)
                        Text(localized: "preferences.made.by")
                            .font(.footnote.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 2)
                    .padding(.bottom, 10)
                }
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .navigationTitle(L("settings.title"))
                .toolbarBackground(.hidden, for: .navigationBar)
            }
        }
    }
    private var versionText: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        return String(format: L("preferences.version"), version)
    }

}



private struct SettingsSectionCard<Content: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .tracking(0.6)
                .foregroundStyle(AppTheme.subtleText(for: colorScheme))

            VStack(spacing: 12) {
                content()
            }
        }
        .dashboardCardStyle()
    }
}

private struct SettingsNavigationRow<Destination: View>: View {
    let title: String
    let iconName: String
    let destination: () -> Destination

    var body: some View {
        NavigationLink {
            destination()
        } label: {
            SettingsRow(title: title, iconName: iconName)
        }
    }
}

private struct SettingsRow: View {
    let title: String
    let iconName: String
    var showsDisclosure = true
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppTheme.chipBackground(for: colorScheme))
                .frame(width: 46, height: 46)
                .overlay(
                    Image(systemName: iconName)
                        .font(.headline)
                        .foregroundStyle(colorScheme == .dark ? Color.white : Color.black)
                )

            Text(title)
                .font(.body.weight(.medium))
                .foregroundStyle(.primary)

            Spacer()

            if showsDisclosure {
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(AppTheme.subtleText(for: colorScheme))
            }
        }
        .padding(.vertical, 6)
    }
}

private enum SupportResources {
    static let privacyPolicyURL = URL(string: "https://www.fittypal.com/privacy.html")
    static let termsOfUseURL = URL(string: "https://www.fittypal.com/terms.html")
    static let supportEmailURL = URL(string: "mailto:support@fittypal.com")
}

#Preview {
    SettingsView(bluetoothManager: BluetoothHeartRateManager())
        .modelContainer(for: [UserProfile.self, Muscle.self, Equipment.self, Exercise.self, Client.self, StrengthExpressionParameters.self], inMemory: true)
}
