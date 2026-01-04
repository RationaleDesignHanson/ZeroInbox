import SwiftUI

/// Loading overlay component for async operations in modals
/// Features customizable message and blur background
struct LoadingState: View {
    var message: String = "Loading..."
    var showMessage: Bool = true
    var blur: Bool = true
    var backgroundColor: Color = Color.black.opacity(0.3)

    var body: some View {
        ZStack {
            // Background overlay
            if blur {
                Rectangle()
                    .fill(backgroundColor)
                    .ignoresSafeArea()
            }

            // Loading indicator
            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)

                if showMessage {
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
            }
            .padding(30)
            .background(.ultraThinMaterial)
            .cornerRadius(DesignTokens.Radius.card)
            .shadow(color: Color.black.opacity(0.2), radius: 10)
        }
    }
}

/// Empty state component for when there's no data to display
struct EmptyState: View {
    let icon: String
    let title: String
    let message: String?
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    init(
        icon: String,
        title: String,
        message: String? = nil,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.5))

            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)

                if let message = message {
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Error banner component for displaying error messages in modals
struct ModalErrorBanner: View {
    let title: String
    let message: String?
    var icon: String = "exclamationmark.triangle.fill"
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    var onDismiss: (() -> Void)? = nil

    init(
        title: String,
        message: String? = nil,
        icon: String = "exclamationmark.triangle.fill",
        actionTitle: String? = nil,
        action: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.icon = icon
        self.actionTitle = actionTitle
        self.action = action
        self.onDismiss = onDismiss
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.red)

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)

                if let message = message {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let actionTitle = actionTitle, let action = action {
                    Button(action: action) {
                        Text(actionTitle)
                            .font(.caption.bold())
                            .foregroundColor(.red)
                    }
                    .padding(.top, 4)
                }
            }

            Spacer()

            if let onDismiss = onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary.opacity(0.5))
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(DesignTokens.Spacing.component)
        .background(Color.red.opacity(0.1))
        .cornerRadius(DesignTokens.Radius.card)
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
                .strokeBorder(Color.red.opacity(0.3), lineWidth: 1)
        )
    }
}

/// Success banner component for displaying success messages in modals
struct ModalSuccessBanner: View {
    let title: String
    let message: String?
    var onDismiss: (() -> Void)? = nil

    init(
        title: String,
        message: String? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.onDismiss = onDismiss
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundColor(.green)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)

                if let message = message {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if let onDismiss = onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary.opacity(0.5))
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(DesignTokens.Spacing.component)
        .background(Color.green.opacity(0.1))
        .cornerRadius(DesignTokens.Radius.card)
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
                .strokeBorder(Color.green.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - View Extensions

extension View {
    /// Apply loading overlay to any view
    func loadingOverlay(isLoading: Bool, message: String = "Loading...") -> some View {
        ZStack {
            self

            if isLoading {
                LoadingState(message: message)
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct LoadingState_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
            // Loading states
            Group {
                LoadingState()

                LoadingState(message: "Processing payment...")

                LoadingState(showMessage: false)

                LoadingState(message: "Uploading...", blur: false)
            }

            Divider()

            // Empty states
            EmptyState(
                icon: "tray",
                title: "No Items",
                message: "There are no items to display"
            )

            EmptyState(
                icon: "magnifyingglass",
                title: "No Results",
                message: "Try adjusting your search",
                actionTitle: "Clear Filters",
                action: {}
            )

            Divider()

            // Error banner
            ModalErrorBanner(
                title: "Failed to Load",
                message: "Unable to fetch data. Please check your connection.",
                actionTitle: "Retry",
                action: {},
                onDismiss: {}
            )

            // Success banner
            ModalSuccessBanner(
                title: "Payment Successful",
                message: "Your payment has been processed",
                onDismiss: {}
            )
        }
        .padding()
    }
}
#endif
