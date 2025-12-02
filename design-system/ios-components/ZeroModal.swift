//
//  ZeroModal.swift
//  Zero Design System
//
//  READY TO INTEGRATE - Drop into: Zero_ios_2/Zero/Core/UI/Components/
//  Requires: DesignTokens.swift in Zero/Config/
//
//  Usage:
//  .sheet(isPresented: $showModal) {
//      ZeroModal(
//          title: "Confirm Action",
//          subtitle: "Are you sure?",
//          primaryButton: ("Confirm", { /* action */ }),
//          secondaryButton: ("Cancel", { /* action */ })
//      )
//  }
//

import SwiftUI

struct ZeroModal<Content: View>: View {
    // MARK: - Types

    enum Size {
        case small    // 360pt wide
        case standard // 480pt wide
        case large    // 640pt wide

        var width: CGFloat {
            switch self {
            case .small: return 360
            case .standard: return 480
            case .large: return 640
            }
        }
    }

    // MARK: - Properties

    let title: String
    let subtitle: String?
    let size: Size
    let showCloseButton: Bool
    let primaryButton: (title: String, action: () -> Void)?
    let secondaryButton: (title: String, action: () -> Void)?
    let destructiveButton: (title: String, action: () -> Void)?
    let onDismiss: (() -> Void)?
    let content: Content?

    @Environment(\.dismiss) private var dismiss

    // MARK: - Initializers

    // Standard modal with buttons
    init(
        title: String,
        subtitle: String? = nil,
        size: Size = .standard,
        showCloseButton: Bool = true,
        primaryButton: (String, () -> Void)? = nil,
        secondaryButton: (String, () -> Void)? = nil,
        destructiveButton: (String, () -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) where Content == EmptyView {
        self.title = title
        self.subtitle = subtitle
        self.size = size
        self.showCloseButton = showCloseButton
        self.primaryButton = primaryButton
        self.secondaryButton = secondaryButton
        self.destructiveButton = destructiveButton
        self.onDismiss = onDismiss
        self.content = nil
    }

    // Custom content modal
    init(
        title: String,
        subtitle: String? = nil,
        size: Size = .standard,
        showCloseButton: Bool = true,
        primaryButton: (String, () -> Void)? = nil,
        secondaryButton: (String, () -> Void)? = nil,
        destructiveButton: (String, () -> Void)? = nil,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.size = size
        self.showCloseButton = showCloseButton
        self.primaryButton = primaryButton
        self.secondaryButton = secondaryButton
        self.destructiveButton = destructiveButton
        self.onDismiss = onDismiss
        self.content = content()
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(DesignTokens.Typography.titleLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignTokens.Colors.textPrimary)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(DesignTokens.Typography.bodySmall)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                }

                Spacer()

                if showCloseButton {
                    Button(action: handleDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                            .frame(width: 32, height: 32)
                            .background(DesignTokens.Colors.overlay10)
                            .clipShape(Circle())
                    }
                }
            }
            .padding(DesignTokens.Spacing.modal)

            Divider()

            // Content
            if let content = content {
                ScrollView {
                    content
                        .padding(DesignTokens.Spacing.modal)
                }
            }

            // Action buttons
            if hasButtons {
                Divider()

                HStack(spacing: DesignTokens.Spacing.element) {
                    if let secondary = secondaryButton {
                        ZeroButton(
                            title: secondary.title,
                            style: .secondary,
                            size: .large
                        ) {
                            secondary.action()
                            handleDismiss()
                        }
                    }

                    if let destructive = destructiveButton {
                        ZeroButton(
                            title: destructive.title,
                            style: .destructive,
                            size: .large
                        ) {
                            destructive.action()
                            handleDismiss()
                        }
                    }

                    if let primary = primaryButton {
                        ZeroButton(
                            title: primary.title,
                            style: .primary,
                            size: .large
                        ) {
                            primary.action()
                            handleDismiss()
                        }
                    }
                }
                .padding(DesignTokens.Spacing.modal)
            }
        }
        .frame(width: size.width)
        .background(DesignTokens.Colors.surfacePrimary)
        .cornerRadius(DesignTokens.Radius.modal)
        .shadow(color: Color.black.opacity(0.25), radius: 24, x: 0, y: 8)
    }

    // MARK: - Computed Properties

    private var hasButtons: Bool {
        primaryButton != nil || secondaryButton != nil || destructiveButton != nil
    }

    // MARK: - Methods

    private func handleDismiss() {
        onDismiss?()
        dismiss()
    }
}

// MARK: - Action Picker Modal

struct ZeroActionPicker: View {
    struct Action: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let subtitle: String?
        let action: () -> Void

        init(icon: String, title: String, subtitle: String? = nil, action: @escaping () -> Void) {
            self.icon = icon
            self.title = title
            self.subtitle = subtitle
            self.action = action
        }
    }

    let title: String
    let actions: [Action]
    let onDismiss: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(title)
                    .font(DesignTokens.Typography.titleLarge)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignTokens.Colors.textPrimary)

                Spacer()

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(DesignTokens.Colors.overlay10)
                        .clipShape(Circle())
                }
            }
            .padding(DesignTokens.Spacing.modal)

            Divider()

            // Actions list
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(actions) { action in
                        Button(action: {
                            action.action()
                            onDismiss?()
                            dismiss()
                        }) {
                            HStack(spacing: DesignTokens.Spacing.element) {
                                // Icon
                                Image(systemName: action.icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(DesignTokens.Colors.accentBlue)
                                    .frame(width: 40, height: 40)
                                    .background(DesignTokens.Colors.accentBlue.opacity(0.1))
                                    .clipShape(Circle())

                                // Text
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(action.title)
                                        .font(DesignTokens.Typography.bodyMedium)
                                        .fontWeight(.semibold)
                                        .foregroundColor(DesignTokens.Colors.textPrimary)

                                    if let subtitle = action.subtitle {
                                        Text(subtitle)
                                            .font(DesignTokens.Typography.caption)
                                            .foregroundColor(DesignTokens.Colors.textSecondary)
                                    }
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(DesignTokens.Colors.textTertiary)
                            }
                            .padding(DesignTokens.Spacing.component)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if action.id != actions.last?.id {
                            Divider()
                                .padding(.leading, DesignTokens.Spacing.modal)
                        }
                    }
                }
            }
        }
        .frame(width: 480)
        .background(DesignTokens.Colors.surfacePrimary)
        .cornerRadius(DesignTokens.Radius.modal)
        .shadow(color: Color.black.opacity(0.25), radius: 24, x: 0, y: 8)
    }
}

// MARK: - Previews

#Preview("Confirmation Modal") {
    ZStack {
        Color.black.opacity(0.3)
            .ignoresSafeArea()

        ZeroModal(
            title: "Confirm Action",
            subtitle: "Are you sure you want to proceed?",
            primaryButton: ("Confirm", {}),
            secondaryButton: ("Cancel", {})
        )
    }
}

#Preview("Destructive Modal") {
    ZStack {
        Color.black.opacity(0.3)
            .ignoresSafeArea()

        ZeroModal(
            title: "Delete Email",
            subtitle: "This action cannot be undone",
            destructiveButton: ("Delete", {}),
            secondaryButton: ("Cancel", {})
        )
    }
}

#Preview("Custom Content Modal") {
    ZStack {
        Color.black.opacity(0.3)
            .ignoresSafeArea()

        ZeroModal(
            title: "Add to Calendar",
            subtitle: "Event details",
            primaryButton: ("Add", {}),
            secondaryButton: ("Cancel", {})
        ) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.component) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Event Title")
                        .font(DesignTokens.Typography.bodySmall)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                    Text("Team Meeting")
                        .font(DesignTokens.Typography.bodyLarge)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Date & Time")
                        .font(DesignTokens.Typography.bodySmall)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                    Text("December 20, 2024 at 2:00 PM")
                        .font(DesignTokens.Typography.bodyLarge)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Location")
                        .font(DesignTokens.Typography.bodySmall)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                    Text("Conference Room A")
                        .font(DesignTokens.Typography.bodyLarge)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                }
            }
        }
    }
}

#Preview("Action Picker") {
    ZStack {
        Color.black.opacity(0.3)
            .ignoresSafeArea()

        ZeroActionPicker(
            title: "Choose Action",
            actions: [
                .init(icon: "calendar.badge.plus", title: "Add to Calendar", subtitle: "Create a calendar event") {},
                .init(icon: "bell.badge", title: "Set Reminder", subtitle: "Get notified later") {},
                .init(icon: "arrow.turn.up.right", title: "Reply", subtitle: "Send a response") {},
                .init(icon: "star", title: "Mark Important", subtitle: "Flag this email") {},
                .init(icon: "archivebox", title: "Archive", subtitle: "Move to archive") {}
            ],
            onDismiss: nil
        )
    }
}

#Preview("Modal Sizes") {
    VStack(spacing: 40) {
        ZeroModal(
            title: "Small Modal",
            subtitle: "360pt wide",
            size: .small,
            primaryButton: ("OK", {})
        )

        ZeroModal(
            title: "Standard Modal",
            subtitle: "480pt wide",
            size: .standard,
            primaryButton: ("OK", {})
        )

        ZeroModal(
            title: "Large Modal",
            subtitle: "640pt wide",
            size: .large,
            primaryButton: ("OK", {})
        )
    }
    .padding()
}

#Preview("Dark Mode") {
    ZStack {
        Color.black.opacity(0.5)
            .ignoresSafeArea()

        ZeroModal(
            title: "Confirm Action",
            subtitle: "Are you sure you want to proceed?",
            primaryButton: ("Confirm", {}),
            secondaryButton: ("Cancel", {})
        )
    }
    .preferredColorScheme(.dark)
}
