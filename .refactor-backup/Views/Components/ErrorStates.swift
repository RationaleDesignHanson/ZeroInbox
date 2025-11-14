//
//  ErrorStates.swift
//  Zero
//
//  Created by Claude Code on 10/26/25.
//

import SwiftUI

/**
 * ErrorStates - Reusable error handling UI components
 *
 * Provides consistent error display across the app:
 * - Error banners
 * - Error screens
 * - Inline errors
 * - Retry mechanisms
 *
 * Usage:
 * ```swift
 * // Full screen error
 * ErrorView(
 *     error: .networkError,
 *     retryAction: { await loadData() }
 * )
 *
 * // Error banner
 * ErrorBanner(message: "Failed to load emails", type: .error)
 *
 * // Inline error
 * InlineError(message: "Invalid email address")
 * ```
 */

// MARK: - Error Types

// Note: AppError is defined in Utilities/ErrorHandler.swift
// We extend it here with additional UI-specific properties

extension AppError {
    var canRetry: Bool {
        switch self {
        case .network, .emailFetch:
            return true
        case .authentication, .classification, .shopping, .storage, .custom, .unknown:
            return false
        }
    }
}

// MARK: - Error View (Full Screen)

struct ErrorView: View {
    let error: AppError
    let retryAction: (() async -> Void)?

    @State private var isRetrying = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Error icon
            Image(systemName: error.icon)
                .font(.system(size: 60))
                .foregroundColor(error.color)

            // Error title
            Text(error.type.capitalized)
                .font(.title2)
                .fontWeight(.bold)

            // Error message
            Text(error.userFacingMessage)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Retry button
            if error.canRetry, let retryAction = retryAction {
                LoadingButton(
                    title: "Retry",
                    isLoading: isRetrying,
                    action: {
                        Task {
                            isRetrying = true
                            await retryAction()
                            isRetrying = false
                        }
                    }
                )
                .padding(.horizontal, 48)
                .padding(.top, 16)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - Error Banner

struct ErrorBanner: View {
    let message: String
    let type: BannerType
    let dismissAction: (() -> Void)?

    @State private var isVisible = true

    init(message: String, type: BannerType = .error, dismissAction: (() -> Void)? = nil) {
        self.message = message
        self.type = type
        self.dismissAction = dismissAction
    }

    var body: some View {
        if isVisible {
            HStack(spacing: 12) {
                Image(systemName: type.icon)
                    .font(.system(size: 20))
                    .foregroundColor(type.iconColor)

                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                if dismissAction != nil {
                    Button(action: dismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(type.backgroundColor)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
            .padding(.horizontal)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    private func dismiss() {
        withAnimation {
            isVisible = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            dismissAction?()
        }
    }
}

enum BannerType {
    case error
    case warning
    case success
    case info

    var icon: String {
        switch self {
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .success: return "checkmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }

    var iconColor: Color {
        switch self {
        case .error: return .red
        case .warning: return .orange
        case .success: return .green
        case .info: return .blue
        }
    }

    var backgroundColor: Color {
        switch self {
        case .error: return Color.red.opacity(0.1)
        case .warning: return Color.orange.opacity(0.1)
        case .success: return Color.green.opacity(0.1)
        case .info: return Color.blue.opacity(0.1)
        }
    }
}

// MARK: - Inline Error

struct InlineError: View {
    let message: String
    let icon: String

    init(message: String, icon: String = "exclamationmark.circle.fill") {
        self.message = message
        self.icon = icon
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.red)

            Text(message)
                .font(.caption)
                .foregroundColor(.red)

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Error Alert

struct ErrorAlert: ViewModifier {
    @Binding var error: AppError?

    func body(content: Content) -> some View {
        content
            .alert(
                error?.errorDescription ?? "Error",
                isPresented: Binding(
                    get: { error != nil },
                    set: { if !$0 { error = nil } }
                )
            ) {
                Button("OK", role: .cancel) {
                    error = nil
                }
            } message: {
                Text(error?.failureReason ?? "An unknown error occurred")
            }
    }
}

extension View {
    func errorAlert(_ error: Binding<AppError?>) -> some View {
        modifier(ErrorAlert(error: error))
    }
}

// MARK: - Network Error View

struct NetworkErrorView: View {
    let retryAction: (() async -> Void)?

    @State private var isRetrying = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 50))
                .foregroundColor(.orange)

            Text("No Internet Connection")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Please check your internet connection and try again")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if let retryAction = retryAction {
                LoadingButton(
                    title: "Retry",
                    isLoading: isRetrying,
                    action: {
                        Task {
                            isRetrying = true
                            await retryAction()
                            isRetrying = false
                        }
                    }
                )
                .padding(.horizontal, 48)
            }
        }
        .padding()
    }
}

// MARK: - Compact Error Row

struct CompactErrorRow: View {
    let message: String
    let retryAction: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            if let retryAction = retryAction {
                Button("Retry") {
                    retryAction()
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Toast Message

struct ToastMessage: View {
    let message: String
    let type: BannerType
    @Binding var isShowing: Bool

    var body: some View {
        if isShowing {
            VStack {
                Spacer()

                HStack(spacing: 12) {
                    Image(systemName: type.icon)
                        .foregroundColor(type.iconColor)

                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                )
                .padding(.horizontal, 32)
                .padding(.bottom, 100)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.spring(), value: isShowing)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation {
                        isShowing = false
                    }
                }
            }
        }
    }
}

extension View {
    func toast(message: String, type: BannerType = .info, isShowing: Binding<Bool>) -> some View {
        ZStack {
            self
            ToastMessage(message: message, type: type, isShowing: isShowing)
        }
    }
}

// MARK: - Result View

/// Combines loading, error, and content states
struct ResultView<Content: View>: View {
    let isLoading: Bool
    let error: AppError?
    let retryAction: (() async -> Void)?
    let content: () -> Content

    var body: some View {
        Group {
            if isLoading {
                LoadingSpinner(text: "Loading...")
            } else if let error = error {
                ErrorView(error: error, retryAction: retryAction)
            } else {
                content()
            }
        }
    }
}

// MARK: - Preview Helpers

#if DEBUG
struct ErrorStates_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 24) {
                Group {
                    Text("Error Banners")
                        .font(.headline)

                    ErrorBanner(message: "Failed to load emails", type: .error, dismissAction: {})
                    ErrorBanner(message: "No internet connection", type: .warning)
                    ErrorBanner(message: "Email sent successfully", type: .success)
                    ErrorBanner(message: "Premium feature available", type: .info)
                }

                Divider()

                Group {
                    Text("Inline Errors")
                        .font(.headline)

                    InlineError(message: "Invalid email address")
                    InlineError(message: "Password must be at least 8 characters")
                }

                Divider()

                Group {
                    Text("Compact Error Row")
                        .font(.headline)

                    CompactErrorRow(message: "Failed to sync", retryAction: {})
                }

                Divider()

                Group {
                    Text("Network Error")
                        .font(.headline)

                    NetworkErrorView(retryAction: { })
                        .frame(height: 300)
                }
            }
            .padding()
        }

        // Full screen error preview
        ErrorView(error: .network("Network connection failed"), retryAction: { })
            .previewDisplayName("Full Screen Error")

        ErrorView(error: .authentication("Unauthorized access"), retryAction: nil)
            .previewDisplayName("No Retry Error")
    }
}
#endif
