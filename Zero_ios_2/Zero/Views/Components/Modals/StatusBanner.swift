//
//  StatusBanner.swift
//  Zero
//
//  Created by Week 6 Refactoring
//  Purpose: Shared status banner component
//

import SwiftUI

/// Reusable status banner for success/error states
/// Week 6 Refactoring: Consolidates 42+ duplicate status banners
///
/// Usage:
/// ```swift
/// StatusBanner(type: .success, message: "Payment successful!")
/// StatusBanner(type: .error, message: "Network error occurred")
/// StatusBanner(type: .info, message: "Processing your request...")
/// ```
struct StatusBanner: View {
    enum BannerType {
        case success
        case error
        case info
        case warning

        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "exclamationmark.triangle.fill"
            case .info: return "info.circle.fill"
            case .warning: return "exclamationmark.circle.fill"
            }
        }

        var color: Color {
            switch self {
            case .success: return .green
            case .error: return .red
            case .info: return .blue
            case .warning: return .orange
            }
        }
    }

    var type: BannerType
    var message: String
    var isCompact: Bool = false

    var body: some View {
        HStack(spacing: isCompact ? 8 : 12) {
            Image(systemName: type.icon)
                .foregroundColor(type.color)
                .font(isCompact ? .body : .headline)

            Text(message)
                .foregroundColor(type.color)
                .font(isCompact ? .caption : .headline.bold())
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(isCompact ? DesignTokens.Spacing.inline : DesignTokens.Spacing.component)
        .background(type.color.opacity(DesignTokens.Opacity.overlayLight))
        .cornerRadius(DesignTokens.Radius.button)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 16) {
        StatusBanner(type: .success, message: "Payment successful!")
        StatusBanner(type: .error, message: "Network error occurred")
        StatusBanner(type: .info, message: "Processing your request...")
        StatusBanner(type: .warning, message: "Low battery warning")

        Divider()

        StatusBanner(type: .success, message: "Done!", isCompact: true)
        StatusBanner(type: .error, message: "Failed", isCompact: true)
    }
    .padding()
    .background(Color.black)
}

// MARK: - Convenience Extensions

extension StatusBanner {
    /// Create a success banner
    static func success(_ message: String, isCompact: Bool = false) -> StatusBanner {
        StatusBanner(type: .success, message: message, isCompact: isCompact)
    }

    /// Create an error banner
    static func error(_ message: String, isCompact: Bool = false) -> StatusBanner {
        StatusBanner(type: .error, message: message, isCompact: isCompact)
    }

    /// Create an info banner
    static func info(_ message: String, isCompact: Bool = false) -> StatusBanner {
        StatusBanner(type: .info, message: message, isCompact: isCompact)
    }

    /// Create a warning banner
    static func warning(_ message: String, isCompact: Bool = false) -> StatusBanner {
        StatusBanner(type: .warning, message: message, isCompact: isCompact)
    }
}

// MARK: - Migration Notes

/*
 WEEK 6 REFACTORING: StatusBanner Consolidation

 This component replaces 42+ duplicate status banner implementations:

 BEFORE (in every modal):
 ------------------------
 if showSuccess {
     HStack {
         Image(systemName: "checkmark.circle.fill")
             .foregroundColor(.green)
         Text("Payment successful!")
             .foregroundColor(.green)
             .font(.headline.bold())
     }
     .frame(maxWidth: .infinity)
     .padding()
     .background(Color.green.opacity(DesignTokens.Opacity.overlayLight))
     .cornerRadius(DesignTokens.Radius.button)
 }

 if showError, let error = errorMessage {
     HStack {
         Image(systemName: "exclamationmark.triangle.fill")
             .foregroundColor(.red)
         Text(error)
             .foregroundColor(.red)
             .font(.caption)
     }
     .frame(maxWidth: .infinity)
     .padding()
     .background(Color.red.opacity(DesignTokens.Opacity.overlayLight))
     .cornerRadius(DesignTokens.Radius.button)
 }

 AFTER:
 ------
 if showSuccess {
     StatusBanner.success("Payment successful!")
 }

 if showError, let error = errorMessage {
     StatusBanner.error(error)
 }

 Benefits:
 ---------
 1. Single source of truth for status banner styling
 2. Consistent success/error/info/warning states
 3. Type-safe API prevents color/icon mismatches
 4. Reduces ~20 lines per modal = 840+ lines eliminated
 5. Easy to add animation/dismiss functionality later

 Customization Options:
 ----------------------
 - type: BannerType (.success, .error, .info, .warning)
 - message: Status message to display
 - isCompact: Compact size for inline banners (default: false)

 Convenience Methods:
 --------------------
 StatusBanner.success("Done!")
 StatusBanner.error("Failed!")
 StatusBanner.info("Loading...")
 StatusBanner.warning("Low battery")

 Files Using This Component:
 ---------------------------
 (Updated during Phase 2 of Week 6 refactoring)
 - PayInvoiceModal.swift
 - TrackPackageModal.swift
 - WriteReviewModal.swift
 - ContactDriverModal.swift
 - ... (38 more modals)

 Future Enhancements:
 --------------------
 1. Add auto-dismiss after N seconds
 2. Add swipe-to-dismiss gesture
 3. Add animation (slide in/out)
 4. Add haptic feedback
 5. Add action button (e.g., "Retry", "Undo")
 6. Add progress indicator for loading states
 */
