//
//  ZeroAlert.swift
//  Zero Design System
//
//  READY TO INTEGRATE - Drop into: Zero_ios_2/Zero/Core/UI/Components/
//  Requires: DesignTokens.swift in Zero/Config/
//
//  Usage:
//  ZeroAlert(
//      variant: .success,
//      title: "Email Sent",
//      message: "Your message was delivered successfully",
//      isDismissible: true
//  )
//

import SwiftUI

struct ZeroAlert: View {
    // MARK: - Types

    enum Variant {
        case success
        case error
        case warning
        case info

        var backgroundColor: Color {
            switch self {
            case .success: return DesignTokens.Colors.successPrimary.opacity(0.1)
            case .error: return DesignTokens.Colors.errorPrimary.opacity(0.1)
            case .warning: return DesignTokens.Colors.warningPrimary.opacity(0.1)
            case .info: return DesignTokens.Colors.accentBlue.opacity(0.1)
            }
        }

        var iconColor: Color {
            switch self {
            case .success: return DesignTokens.Colors.successPrimary
            case .error: return DesignTokens.Colors.errorPrimary
            case .warning: return DesignTokens.Colors.warningPrimary
            case .info: return DesignTokens.Colors.accentBlue
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

        var borderColor: Color {
            switch self {
            case .success: return DesignTokens.Colors.successPrimary
            case .error: return DesignTokens.Colors.errorPrimary
            case .warning: return DesignTokens.Colors.warningPrimary
            case .info: return DesignTokens.Colors.accentBlue
            }
        }
    }

    enum Style {
        case banner      // Inline banner with border
        case toast       // Floating toast notification
        case inline      // Simple inline message
    }

    // MARK: - Properties

    let variant: Variant
    let style: Style
    let title: String
    let message: String?
    let isDismissible: Bool
    let onDismiss: (() -> Void)?
    let action: (title: String, action: () -> Void)?

    @State private var isVisible: Bool = true

    // MARK: - Initializers

    init(
        variant: Variant,
        style: Style = .banner,
        title: String,
        message: String? = nil,
        isDismissible: Bool = false,
        onDismiss: (() -> Void)? = nil,
        action: (String, () -> Void)? = nil
    ) {
        self.variant = variant
        self.style = style
        self.title = title
        self.message = message
        self.isDismissible = isDismissible
        self.onDismiss = onDismiss
        self.action = action
    }

    // MARK: - Body

    var body: some View {
        if isVisible {
            switch style {
            case .banner:
                bannerView
            case .toast:
                toastView
            case .inline:
                inlineView
            }
        }
    }

    // MARK: - Banner Style

    private var bannerView: some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.element) {
            // Icon
            Image(systemName: variant.icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(variant.iconColor)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(DesignTokens.Typography.bodyMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignTokens.Colors.textPrimary)

                if let message = message {
                    Text(message)
                        .font(DesignTokens.Typography.bodySmall)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }

                // Action button
                if let action = action {
                    Button(action: action.action) {
                        Text(action.title)
                            .font(DesignTokens.Typography.bodySmall)
                            .fontWeight(.semibold)
                            .foregroundColor(variant.iconColor)
                    }
                    .padding(.top, 4)
                }
            }

            Spacer()

            // Dismiss button
            if isDismissible {
                Button(action: handleDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
            }
        }
        .padding(DesignTokens.Spacing.component)
        .background(variant.backgroundColor)
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
                .stroke(variant.borderColor, lineWidth: 1)
        )
        .cornerRadius(DesignTokens.Radius.card)
    }

    // MARK: - Toast Style

    private var toastView: some View {
        HStack(spacing: DesignTokens.Spacing.element) {
            // Icon
            Image(systemName: variant.icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(variant.iconColor)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(DesignTokens.Typography.bodyMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignTokens.Colors.textPrimary)

                if let message = message {
                    Text(message)
                        .font(DesignTokens.Typography.bodySmall)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            // Dismiss button
            if isDismissible {
                Button(action: handleDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
            }
        }
        .padding(DesignTokens.Spacing.component)
        .background(DesignTokens.Colors.surfacePrimary)
        .cornerRadius(DesignTokens.Radius.card)
        .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 4)
    }

    // MARK: - Inline Style

    private var inlineView: some View {
        HStack(spacing: DesignTokens.Spacing.inline) {
            Image(systemName: variant.icon)
                .font(.system(size: 16))
                .foregroundColor(variant.iconColor)

            Text(title)
                .font(DesignTokens.Typography.bodySmall)
                .foregroundColor(DesignTokens.Colors.textPrimary)

            Spacer()

            if isDismissible {
                Button(action: handleDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(DesignTokens.Colors.textTertiary)
                }
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.element)
        .padding(.vertical, DesignTokens.Spacing.inline)
        .background(variant.backgroundColor)
        .cornerRadius(DesignTokens.Radius.button)
    }

    // MARK: - Methods

    private func handleDismiss() {
        withAnimation(.easeOut(duration: 0.2)) {
            isVisible = false
        }
        onDismiss?()
    }
}

// MARK: - Toast Manager (Global notifications)

class ZeroToastManager: ObservableObject {
    static let shared = ZeroToastManager()

    @Published var currentToast: ToastItem?

    struct ToastItem: Identifiable {
        let id = UUID()
        let variant: ZeroAlert.Variant
        let title: String
        let message: String?
        let duration: TimeInterval

        init(
            variant: ZeroAlert.Variant,
            title: String,
            message: String? = nil,
            duration: TimeInterval = 3.0
        ) {
            self.variant = variant
            self.title = title
            self.message = message
            self.duration = duration
        }
    }

    private init() {}

    func show(
        variant: ZeroAlert.Variant,
        title: String,
        message: String? = nil,
        duration: TimeInterval = 3.0
    ) {
        currentToast = ToastItem(
            variant: variant,
            title: title,
            message: message,
            duration: duration
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            self.currentToast = nil
        }
    }

    func dismiss() {
        currentToast = nil
    }
}

// MARK: - Toast Overlay Modifier

struct ZeroToastOverlay: ViewModifier {
    @ObservedObject var toastManager = ZeroToastManager.shared

    func body(content: Content) -> some View {
        ZStack {
            content

            if let toast = toastManager.currentToast {
                VStack {
                    ZeroAlert(
                        variant: toast.variant,
                        style: .toast,
                        title: toast.title,
                        message: toast.message,
                        isDismissible: true,
                        onDismiss: { toastManager.dismiss() }
                    )
                    .padding(.horizontal, DesignTokens.Spacing.component)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.spring(), value: toastManager.currentToast?.id)

                    Spacer()
                }
                .padding(.top, 50)
            }
        }
    }
}

extension View {
    func zeroToastOverlay() -> some View {
        modifier(ZeroToastOverlay())
    }
}

// MARK: - Previews

#Preview("Alert Variants - Banner") {
    VStack(spacing: DesignTokens.Spacing.section) {
        ZeroAlert(
            variant: .success,
            title: "Email Sent Successfully",
            message: "Your message was delivered to sarah@example.com",
            isDismissible: true
        )

        ZeroAlert(
            variant: .error,
            title: "Failed to Send Email",
            message: "Unable to connect to mail server. Please try again.",
            isDismissible: true
        )

        ZeroAlert(
            variant: .warning,
            title: "Storage Almost Full",
            message: "You have less than 100 MB of storage remaining",
            isDismissible: true
        )

        ZeroAlert(
            variant: .info,
            title: "New Feature Available",
            message: "Try our new AI-powered email categorization",
            isDismissible: true
        )
    }
    .padding()
}

#Preview("Alert Styles") {
    VStack(spacing: DesignTokens.Spacing.section) {
        // Banner
        ZeroAlert(
            variant: .success,
            style: .banner,
            title: "Banner Style",
            message: "This is a banner-style alert with border",
            isDismissible: true
        )

        // Toast
        ZeroAlert(
            variant: .info,
            style: .toast,
            title: "Toast Style",
            message: "This is a toast notification with shadow",
            isDismissible: true
        )

        // Inline
        ZeroAlert(
            variant: .warning,
            style: .inline,
            title: "Inline style - compact message",
            isDismissible: true
        )
    }
    .padding()
}

#Preview("With Actions") {
    VStack(spacing: DesignTokens.Spacing.section) {
        ZeroAlert(
            variant: .success,
            title: "Email Archived",
            message: "The email has been moved to your archive",
            isDismissible: true,
            action: ("Undo", {})
        )

        ZeroAlert(
            variant: .warning,
            title: "Low Storage",
            message: "You're running out of storage space",
            isDismissible: true,
            action: ("Upgrade Plan", {})
        )

        ZeroAlert(
            variant: .info,
            title: "New Update Available",
            message: "Version 2.0 is ready to install",
            isDismissible: true,
            action: ("Update Now", {})
        )
    }
    .padding()
}

#Preview("Non-dismissible") {
    VStack(spacing: DesignTokens.Spacing.section) {
        ZeroAlert(
            variant: .error,
            title: "Connection Lost",
            message: "Unable to connect to the internet",
            isDismissible: false
        )

        ZeroAlert(
            variant: .warning,
            title: "Syncing...",
            message: "Please wait while we sync your data",
            isDismissible: false
        )
    }
    .padding()
}

#Preview("Toast Manager Demo") {
    VStack(spacing: DesignTokens.Spacing.element) {
        ZeroButton(title: "Show Success Toast", style: .primary) {
            ZeroToastManager.shared.show(
                variant: .success,
                title: "Email Sent",
                message: "Your message was delivered successfully"
            )
        }

        ZeroButton(title: "Show Error Toast", style: .destructive) {
            ZeroToastManager.shared.show(
                variant: .error,
                title: "Failed to Send",
                message: "Please check your connection"
            )
        }

        ZeroButton(title: "Show Info Toast", style: .secondary) {
            ZeroToastManager.shared.show(
                variant: .info,
                title: "New Feature",
                message: "Check out our latest update"
            )
        }
    }
    .padding()
    .zeroToastOverlay()
}

#Preview("In Context") {
    ScrollView {
        VStack(spacing: DesignTokens.Spacing.component) {
            // Page header
            VStack(alignment: .leading, spacing: 8) {
                Text("Inbox")
                    .font(DesignTokens.Typography.titleLarge)
                    .fontWeight(.bold)
                Text("12 unread messages")
                    .font(DesignTokens.Typography.bodySmall)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Alert in context
            ZeroAlert(
                variant: .info,
                title: "Auto-Archive Enabled",
                message: "Emails older than 30 days will be automatically archived",
                isDismissible: true,
                action: ("Settings", {})
            )

            // Email list
            VStack(spacing: 0) {
                ForEach(0..<3) { _ in
                    ZeroEmailListItem(
                        sender: "Sarah Chen",
                        subject: "Q4 Budget Review",
                        preview: "Hi team, I've scheduled our quarterly budget review...",
                        timestamp: "2h ago",
                        isUnread: true,
                        isStarred: false,
                        hasAttachment: true,
                        isSelected: false,
                        onTap: nil,
                        onStar: nil
                    )
                    Divider()
                }
            }
        }
        .padding()
    }
}

#Preview("Dark Mode") {
    VStack(spacing: DesignTokens.Spacing.section) {
        ZeroAlert(
            variant: .success,
            title: "Email Sent",
            message: "Your message was delivered successfully",
            isDismissible: true
        )

        ZeroAlert(
            variant: .error,
            title: "Failed to Send",
            message: "Unable to connect to mail server",
            isDismissible: true
        )

        ZeroAlert(
            variant: .info,
            style: .toast,
            title: "New Feature Available",
            message: "Try our new AI-powered categorization",
            isDismissible: true
        )
    }
    .padding()
    .preferredColorScheme(.dark)
}
