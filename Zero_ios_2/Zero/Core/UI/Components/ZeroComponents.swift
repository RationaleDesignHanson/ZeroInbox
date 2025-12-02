import SwiftUI

// MARK: - Zero Design System Components
// Phase 0 Day 3: Reusable SwiftUI components using DesignTokens
// These components match the Figma component library built in Day 2

// MARK: - ZeroButton

/// Primary interaction button with multiple styles, sizes, and states
/// Matches Figma component: Components/ZeroButton
struct ZeroButton: View {
    enum Style {
        case primary
        case secondary
        case destructive
        case text

        var backgroundColor: Color {
            switch self {
            case .primary:
                return Color.blue // TODO: Use gradient from design tokens
            case .secondary:
                return Color.white.opacity(0.1)
            case .destructive:
                return Color.red
            case .text:
                return Color.clear
            }
        }

        var foregroundColor: Color {
            switch self {
            case .primary, .secondary, .destructive:
                return .white
            case .text:
                return .white
            }
        }
    }

    enum Size {
        case large
        case medium
        case small

        var height: CGFloat {
            switch self {
            case .large: return 56
            case .medium: return 44
            case .small: return 32
            }
        }

        var fontSize: CGFloat {
            switch self {
            case .large: return 15
            case .medium: return 14
            case .small: return 13
            }
        }

        var horizontalPadding: CGFloat {
            return DesignTokens.Spacing.component
        }
    }

    // MARK: - Properties

    let title: String
    let icon: String? // SF Symbol name
    let style: Style
    let size: Size
    let isEnabled: Bool
    let action: () -> Void

    // MARK: - Initializer

    init(
        _ title: String,
        icon: String? = nil,
        style: Style = .primary,
        size: Size = .large,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.size = size
        self.isEnabled = isEnabled
        self.action = action
    }

    // MARK: - Body

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.Spacing.inline) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                }
                Text(title)
                    .font(.system(size: size.fontSize, weight: .medium))
            }
            .foregroundColor(style.foregroundColor)
            .frame(maxWidth: .infinity, minHeight: size.height)
            .padding(.horizontal, size.horizontalPadding)
            .background(style.backgroundColor)
            .cornerRadius(DesignTokens.Radius.button)
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : DesignTokens.Opacity.textDisabled)
    }
}

// MARK: - ZeroCard

/// Email card component for inbox feed
/// Matches Figma component: Components/ZeroCard
struct ZeroCard: View {
    enum State {
        case `default`
        case focused
        case expanded

        var borderOpacity: Double {
            switch self {
            case .default, .expanded: return 0
            case .focused: return 0.3
            }
        }

        var showGlow: Bool {
            self == .focused
        }
    }

    // MARK: - Properties

    let title: String
    let summary: String
    let timestamp: String?
    let priority: Priority?
    let actions: [CardAction]
    let state: State
    let onTap: () -> Void

    struct CardAction {
        let title: String
        let icon: String?
        let style: ZeroButton.Style
        let action: () -> Void
    }

    enum Priority {
        case high
        case medium
        case low

        var color: Color {
            switch self {
            case .high: return .red
            case .medium: return .yellow
            case .low: return .blue
            }
        }

        var label: String {
            switch self {
            case .high: return "High"
            case .medium: return "Medium"
            case .low: return "Low"
            }
        }
    }

    // MARK: - Initializer

    init(
        title: String,
        summary: String,
        timestamp: String? = nil,
        priority: Priority? = nil,
        actions: [CardAction] = [],
        state: State = .default,
        onTap: @escaping () -> Void
    ) {
        self.title = title
        self.summary = summary
        self.timestamp = timestamp
        self.priority = priority
        self.actions = actions
        self.state = state
        self.onTap = onTap
    }

    // MARK: - Body

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.element) {
                // Header
                HStack(spacing: DesignTokens.Spacing.inline) {
                    if let priority = priority {
                        PriorityBadge(priority: priority)
                    }

                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Spacer()

                    if let timestamp = timestamp {
                        Text(timestamp)
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
                    }
                }

                // Summary
                Text(summary)
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(DesignTokens.Opacity.textSecondary))
                    .lineLimit(state == .expanded ? nil : 3)

                // Actions
                if !actions.isEmpty {
                    HStack(spacing: DesignTokens.Spacing.inline) {
                        ForEach(actions.indices, id: \.self) { index in
                            let action = actions[index]
                            ZeroButton(
                                action.title,
                                icon: action.icon,
                                style: action.style,
                                size: .small,
                                action: action.action
                            )
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(DesignTokens.Spacing.card)
            .background(
                Color.white.opacity(DesignTokens.Opacity.glassLight)
            )
            .cornerRadius(DesignTokens.Radius.card)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
                    .stroke(Color.white.opacity(state.borderOpacity), lineWidth: 2)
            )
            .shadow(
                color: state.showGlow ? Color.white.opacity(0.2) : .clear,
                radius: 8,
                x: 0,
                y: 0
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Priority Badge

private struct PriorityBadge: View {
    let priority: ZeroCard.Priority

    var body: some View {
        Text(priority.label)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(priority.color.opacity(0.3))
            .cornerRadius(DesignTokens.Radius.chip)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.chip)
                    .stroke(priority.color.opacity(0.5), lineWidth: 1)
            )
    }
}

// MARK: - ZeroModal

/// Modal overlay component for dialogs and action sheets
/// Matches Figma component: Components/ZeroModal
struct ZeroModal: View {
    enum ModalType {
        case standard
        case actionPicker
        case confirmation

        var height: CGFloat? {
            switch self {
            case .standard, .confirmation: return nil // Hug contents
            case .actionPicker: return 500
            }
        }
    }

    // MARK: - Properties

    let type: ModalType
    let title: String
    let subtitle: String?
    let body: AnyView?
    let buttons: [ModalButton]
    let onDismiss: () -> Void

    struct ModalButton {
        let title: String
        let style: ZeroButton.Style
        let action: () -> Void
    }

    // MARK: - Initializer

    init(
        type: ModalType = .standard,
        title: String,
        subtitle: String? = nil,
        body: AnyView? = nil,
        buttons: [ModalButton],
        onDismiss: @escaping () -> Void
    ) {
        self.type = type
        self.title = title
        self.subtitle = subtitle
        self.body = body
        self.buttons = buttons
        self.onDismiss = onDismiss
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Backdrop
            Color.black
                .opacity(DesignTokens.Opacity.overlayStrong)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }

            // Modal
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.component) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(DesignTokens.Opacity.textSecondary))
                    }
                }

                // Body
                if let body = body {
                    body
                }

                // Footer (Buttons)
                HStack(spacing: DesignTokens.Spacing.element) {
                    Spacer()
                    ForEach(buttons.indices, id: \.self) { index in
                        let button = buttons[index]
                        ZeroButton(
                            button.title,
                            style: button.style,
                            size: .medium,
                            action: {
                                button.action()
                                onDismiss()
                            }
                        )
                    }
                }
            }
            .frame(width: 335, height: type.height)
            .padding(DesignTokens.Spacing.modal)
            .background(
                Color.white.opacity(0.15)
                    .background(.ultraThinMaterial)
            )
            .cornerRadius(DesignTokens.Radius.modal)
        }
    }
}

// MARK: - ZeroListItem

/// Reusable list item for settings and action selection
/// Matches Figma component: Components/ZeroListItem
struct ZeroListItem: View {
    enum ItemState {
        case `default`
        case selected
        case disabled

        var backgroundColor: Color {
            switch self {
            case .default, .disabled: return .clear
            case .selected: return Color.white.opacity(0.1)
            }
        }

        var opacity: Double {
            self == .disabled ? DesignTokens.Opacity.textDisabled : 1.0
        }
    }

    // MARK: - Properties

    let label: String
    let icon: String?
    let badge: String?
    let hasArrow: Bool
    let state: ItemState
    let action: () -> Void

    // MARK: - Initializer

    init(
        _ label: String,
        icon: String? = nil,
        badge: String? = nil,
        hasArrow: Bool = false,
        state: ItemState = .default,
        action: @escaping () -> Void
    ) {
        self.label = label
        self.icon = icon
        self.badge = badge
        self.hasArrow = hasArrow
        self.state = state
        self.action = action
    }

    // MARK: - Body

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.Spacing.element) {
                // Leading icon
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)
                }

                // Label
                Text(label)
                    .font(.system(size: 16))
                    .foregroundColor(.white)

                Spacer()

                // Trailing badge
                if let badge = badge {
                    Text(badge)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.3))
                        .cornerRadius(DesignTokens.Radius.circle)
                }

                // Trailing arrow
                if hasArrow {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(DesignTokens.Spacing.element)
            .background(state.backgroundColor)
            .cornerRadius(DesignTokens.Radius.minimal)
        }
        .disabled(state == .disabled)
        .opacity(state.opacity)
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - ZeroAlert

/// Toast/banner alert for user feedback
/// Matches Figma component: Components/ZeroAlert
struct ZeroAlert: View {
    enum AlertType {
        case success
        case error
        case warning
        case info

        var color: Color {
            switch self {
            case .success: return Color.green
            case .error: return Color.red
            case .warning: return Color.yellow
            case .info: return Color.blue
            }
        }

        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "xmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .info: return "info.circle.fill"
            }
        }
    }

    // MARK: - Properties

    let type: AlertType
    let title: String
    let message: String?
    let hasCloseButton: Bool
    let onDismiss: (() -> Void)?

    // MARK: - Initializer

    init(
        type: AlertType,
        title: String,
        message: String? = nil,
        hasCloseButton: Bool = true,
        onDismiss: (() -> Void)? = nil
    ) {
        self.type = type
        self.title = title
        self.message = message
        self.hasCloseButton = hasCloseButton
        self.onDismiss = onDismiss
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.element) {
            // Icon
            Image(systemName: type.icon)
                .font(.system(size: 24))
                .foregroundColor(type.color)

            // Text content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                if let message = message {
                    Text(message)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(DesignTokens.Opacity.textSecondary))
                }
            }

            Spacer()

            // Close button
            if hasCloseButton, let onDismiss = onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(DesignTokens.Spacing.component)
        .background(
            type.color.opacity(0.2)
        )
        .cornerRadius(DesignTokens.Radius.button)
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                .stroke(type.color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Preview Helpers

#if DEBUG
struct ZeroComponents_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 24) {
                // ZeroButton examples
                Group {
                    Text("ZeroButton").font(.headline)
                    ZeroButton("Primary Button", icon: "star.fill", style: .primary) {}
                    ZeroButton("Secondary Button", style: .secondary) {}
                    ZeroButton("Destructive Button", style: .destructive) {}
                    ZeroButton("Text Button", style: .text) {}
                    ZeroButton("Small Button", style: .primary, size: .small) {}
                }

                // ZeroCard example
                Group {
                    Text("ZeroCard").font(.headline)
                    ZeroCard(
                        title: "Meeting Reminder",
                        summary: "Team standup in 15 minutes. Join the call using the link below.",
                        timestamp: "2m ago",
                        priority: .high,
                        actions: [
                            .init(title: "Join", icon: "video.fill", style: .primary) {},
                            .init(title: "Snooze", icon: nil, style: .secondary) {}
                        ]
                    ) {}
                }

                // ZeroListItem examples
                Group {
                    Text("ZeroListItem").font(.headline)
                    ZeroListItem("Settings", icon: "gear", hasArrow: true) {}
                    ZeroListItem("Notifications", icon: "bell.fill", badge: "3", hasArrow: true) {}
                    ZeroListItem("Disabled Item", icon: "lock.fill", state: .disabled) {}
                }

                // ZeroAlert examples
                Group {
                    Text("ZeroAlert").font(.headline)
                    ZeroAlert(type: .success, title: "Email sent successfully") {}
                    ZeroAlert(type: .error, title: "Failed to connect", message: "Check your internet connection") {}
                    ZeroAlert(type: .warning, title: "Low storage") {}
                    ZeroAlert(type: .info, title: "New feature available") {}
                }
            }
            .padding()
        }
        .background(Color.black)
        .preferredColorScheme(.dark)
    }
}
#endif
