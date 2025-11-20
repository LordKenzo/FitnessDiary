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
                        Text(L(theme.localizationKey))
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
        return AppTheme.blobColor(for: theme, primary: primary)
    }
}

#Preview {
    NavigationStack {
        ThemeSelectionView()
            .environment(ThemeManager.shared)
    }
}
