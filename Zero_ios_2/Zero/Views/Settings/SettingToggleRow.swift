import SwiftUI

/// Reusable toggle setting row component
/// Eliminates ~35 lines of duplicate code per toggle setting
struct SettingToggleRow: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    @Binding var isOn: Bool
    let onChange: ((Bool) -> Void)?

    @Environment(\.colorScheme) var colorScheme

    init(
        title: String,
        description: String,
        icon: String,
        color: Color,
        isOn: Binding<Bool>,
        onChange: ((Bool) -> Void)? = nil
    ) {
        self.title = title
        self.description = description
        self.icon = icon
        self.color = color
        self._isOn = isOn
        self.onChange = onChange
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: $isOn) {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(color)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.subheadline.bold())
                            .foregroundColor(textColor)

                        Text(description)
                            .font(.caption)
                            .foregroundColor(textColor.opacity(DesignTokens.Opacity.textDisabled))
                    }
                }
            }
            .tint(color)
            .onChange(of: isOn) { _, newValue in
                HapticService.shared.mediumImpact()
                onChange?(newValue)
            }
        }
        .glassCard(borderColor: color)
        .padding(.horizontal, DesignTokens.Spacing.section)
    }

    private var textColor: Color {
        // Settings screen always has dark background, so always use white text
        .white
    }
}

/// Toggle row with extra content below (e.g., warning message, count display)
struct SettingToggleRowWithExtra<ExtraContent: View>: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    @Binding var isOn: Bool
    let onChange: ((Bool) -> Void)?
    let extraContent: () -> ExtraContent

    @Environment(\.colorScheme) var colorScheme

    init(
        title: String,
        description: String,
        icon: String,
        color: Color,
        isOn: Binding<Bool>,
        onChange: ((Bool) -> Void)? = nil,
        @ViewBuilder extraContent: @escaping () -> ExtraContent
    ) {
        self.title = title
        self.description = description
        self.icon = icon
        self.color = color
        self._isOn = isOn
        self.onChange = onChange
        self.extraContent = extraContent
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: $isOn) {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(color)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.subheadline.bold())
                            .foregroundColor(textColor)

                        Text(description)
                            .font(.caption)
                            .foregroundColor(textColor.opacity(DesignTokens.Opacity.textDisabled))
                    }
                }
            }
            .tint(color)
            .onChange(of: isOn) { _, newValue in
                HapticService.shared.mediumImpact()
                onChange?(newValue)
            }

            // Extra content (warning, count, etc.)
            extraContent()
        }
        .glassCard(borderColor: color)
        .padding(.horizontal, DesignTokens.Spacing.section)
    }

    private var textColor: Color {
        // Settings screen always has dark background, so always use white text
        .white
    }
}
