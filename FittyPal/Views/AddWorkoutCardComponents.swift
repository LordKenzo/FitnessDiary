import SwiftUI

// MARK: - Selectable Chip Component
struct SelectableChip: View {
    let icon: String
    let label: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                action()
            }
        }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .white : color)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(isSelected ? color : color.opacity(0.15))
                    )

                Text(label)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? Color.white.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? color.opacity(0.5) : Color.clear, lineWidth: 1.5)
            )
            .scaleEffect(isSelected ? 1.0 : 0.95)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Section Card Container
struct SectionCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String?
    let content: Content

    init(title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title = title {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }

            content
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.cardBackground(for: colorScheme))
        .background(.thinMaterial.opacity(colorScheme == .dark ? 0.25 : 0.4))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(AppTheme.stroke(for: colorScheme), lineWidth: 1)
        )
        .shadow(color: AppTheme.shadow(for: colorScheme), radius: 20, y: 10)
    }
}

// MARK: - Info Badge
struct InfoBadge: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(color.opacity(0.15))
        )
    }
}

// MARK: - Enhanced Block Row
struct EnhancedBlockRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let block: WorkoutBlock
    let order: Int

    var body: some View {
        HStack(spacing: 14) {
            // Order badge
            Text("\(order)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(accentColor.opacity(0.8))
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: blockIcon)
                        .font(.subheadline)
                        .foregroundStyle(accentColor)

                    Text(block.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }

                Text(block.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if block.blockType != .rest, let restTime = block.globalRestTime, restTime > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.caption2)
                        Text(block.formattedRestTime ?? "")
                            .font(.caption2)
                    }
                    .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.cardBackground(for: colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(accentColor.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private var accentColor: Color {
        if block.blockType == .method, let method = block.methodType {
            return method.color
        } else if block.blockType == .rest {
            return .orange
        }
        return .blue
    }

    private var blockIcon: String {
        if block.blockType == .method, let method = block.methodType {
            return method.icon
        } else if block.blockType == .rest {
            return "moon.zzz.fill"
        }
        return "figure.strengthtraining.traditional"
    }
}

// MARK: - Floating Action Button
struct FloatingActionButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.headline)
                Text(label)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .shadow(color: .blue.opacity(0.4), radius: 15, y: 8)
        }
        .buttonStyle(.plain)
    }
}
