import SwiftUI

/// Shared glassmorphic building blocks used across the in-app libraries
/// (muscles, equipment, exercises, workout cards) so every list row and
/// section matches the refreshed dashboard/Settings styling.
struct GlassSectionCard<Content: View>: View {
    let title: String
    var subtitle: String? = nil
    var iconName: String
    @ViewBuilder var content: () -> Content

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppTheme.chipBackground(for: colorScheme))
                    .frame(width: 52, height: 52)
                    .overlay(
                        Image(systemName: iconName)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title3.weight(.semibold))
                    if let subtitle {
                        Text(subtitle)
                            .font(.footnote)
                            .foregroundStyle(AppTheme.subtleText(for: colorScheme))
                    }
                }
            }

            VStack(spacing: 12) {
                content()
            }
        }
        .dashboardCardStyle()
    }
}

struct GlassListRow<Trailing: View>: View {
    let title: String
    var subtitle: String? = nil
    var iconName: String
    var iconTint: Color = .accentColor
    @ViewBuilder var trailing: () -> Trailing

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(iconTint.opacity(colorScheme == .dark ? 0.45 : 0.2))
                .overlay(
                    Image(systemName: iconName)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(iconTint)
                )
                .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(AppTheme.subtleText(for: colorScheme))
                }
            }

            Spacer(minLength: 12)

            trailing()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppTheme.cardBackground(for: colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(AppTheme.stroke(for: colorScheme), lineWidth: 1)
                )
        )
    }
}

extension GlassListRow where Trailing == EmptyView {
    init(title: String, subtitle: String? = nil, iconName: String, iconTint: Color = .accentColor) {
        self.title = title
        self.subtitle = subtitle
        self.iconName = iconName
        self.iconTint = iconTint
        self.trailing = { EmptyView() }
    }
}

struct GlassEmptyStateCard<Actions: View>: View {
    let systemImage: String
    let title: String
    let description: String
    @ViewBuilder var actions: () -> Actions

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 48, weight: .semibold))
                .foregroundStyle(.orange)

            VStack(spacing: 6) {
                Text(title)
                    .font(.title3.weight(.semibold))
                Text(description)
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppTheme.subtleText(for: colorScheme))
            }

            actions()
        }
        .multilineTextAlignment(.center)
        .dashboardCardStyle()
    }
}

extension GlassEmptyStateCard where Actions == EmptyView {
    init(systemImage: String, title: String, description: String) {
        self.systemImage = systemImage
        self.title = title
        self.description = description
        self.actions = { EmptyView() }
    }
}
