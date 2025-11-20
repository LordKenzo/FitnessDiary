import SwiftUI

struct ThemeSelectionView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        AppBackgroundView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header description
                    Text(L("preferences.theme.description"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    // Theme cards
                    VStack(spacing: 16) {
                        ForEach(ThemeManager.availableThemes) { theme in
                            ThemePreviewCard(
                                theme: theme,
                                isSelected: themeManager.currentTheme == theme
                            ) {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                    themeManager.currentTheme = theme
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle(L("preferences.theme.title"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Theme Preview Card
private struct ThemePreviewCard: View {
    let theme: AppColorTheme
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                // Gradient preview
                ZStack {
                    AppTheme.backgroundGradient(for: theme)

                    // Blob preview
                    GeometryReader { geometry in
                        ZStack {
                            Circle()
                                .fill(blobColor(primary: true))
                                .frame(width: geometry.size.width * 0.4)
                                .blur(radius: 40)
                                .offset(x: -30, y: -20)

                            Circle()
                                .fill(blobColor())
                                .frame(width: geometry.size.width * 0.5)
                                .blur(radius: 50)
                                .offset(x: 40, y: 10)
                        }
                    }

                    // Theme icon
                    Image(systemName: theme.icon)
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                }
                .frame(height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                // Theme info
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(theme.displayName)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)

                        Text(theme.colorScheme == .dark ? L("preferences.theme.dark") : L("preferences.theme.light"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }
                }
                .padding(16)
            }
            .background(AppTheme.cardBackground(for: theme.colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(isSelected ? Color.blue : AppTheme.stroke(for: theme.colorScheme), lineWidth: isSelected ? 2.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func blobColor(primary: Bool = false) -> Color {
        switch theme {
        case .vibrant:
            return Color(red: primary ? 255/255 : 226/255, green: primary ? 102/255 : 70/255, blue: primary ? 196/255 : 125/255)
                .opacity(primary ? 0.32 : 0.22)
        case .ocean:
            return Color(red: primary ? 80/255 : 100/255, green: primary ? 180/255 : 200/255, blue: primary ? 255/255 : 220/255)
                .opacity(primary ? 0.28 : 0.18)
        case .sunset:
            return Color(red: primary ? 255/255 : 255/255, green: primary ? 140/255 : 180/255, blue: primary ? 100/255 : 130/255)
                .opacity(primary ? 0.35 : 0.25)
        case .forest:
            return Color(red: primary ? 100/255 : 120/255, green: primary ? 200/255 : 180/255, blue: primary ? 100/255 : 120/255)
                .opacity(primary ? 0.25 : 0.18)
        case .sunrise:
            return Color(red: primary ? 200/255 : 180/255, green: primary ? 160/255 : 180/255, blue: primary ? 255/255 : 240/255)
                .opacity(primary ? 0.30 : 0.20)
        case .lavender:
            return Color(red: primary ? 200/255 : 180/255, green: primary ? 160/255 : 180/255, blue: primary ? 255/255 : 240/255)
                .opacity(primary ? 0.30 : 0.20)
        case .fittypal:
            return Color(red: primary ? 80/255 : 100/255, green: primary ? 220/255 : 200/255, blue: primary ? 180/255 : 160/255)
                .opacity(primary ? 0.35 : 0.25)
        case .yellowstone:
            return Color(red: primary ? 80/255 : 100/255, green: primary ? 220/255 : 200/255, blue: primary ? 180/255 : 160/255)
                .opacity(primary ? 0.35 : 0.25)
        case .christmas:
            return Color(red: primary ? 220/255 : 180/255, green: primary ? 50/255 : 180/255, blue: primary ? 50/255 : 50/255)
                .opacity(primary ? 0.30 : 0.22)
        }
    }
}

#Preview {
    NavigationStack {
        ThemeSelectionView()
            .environment(ThemeManager.shared)
    }
}
