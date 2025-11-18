//
//  ModalHeader.swift
//  Zero
//
//  Created by Week 6 Refactoring
//  Purpose: Shared modal header component
//

import SwiftUI

/// Reusable modal header with close button
/// Week 6 Refactoring: Consolidates 46 duplicate modal headers
///
/// Usage:
/// ```swift
/// ModalHeader(isPresented: $isPresented)
/// ModalHeader(isPresented: $isPresented, title: "Settings")
/// ModalHeader(isPresented: $isPresented, title: "Open App", subtitle: "Launch app to complete")
/// ModalHeader(isPresented: $isPresented, title: "Attachments", subtitle: "3 files", alignment: .center)
/// ```
struct ModalHeader: View {
    @Binding var isPresented: Bool
    var title: String? = nil
    var subtitle: String? = nil
    var alignment: HeaderAlignment = .leading
    var showDivider: Bool = false
    var titleFont: Font = .title2.bold()
    var subtitleFont: Font = .subheadline

    enum HeaderAlignment {
        case leading
        case center
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header content
            if alignment == .center {
                centeredHeader
            } else {
                leadingHeader
            }

            if showDivider {
                Divider()
                    .background(Color.white.opacity(DesignTokens.Opacity.overlayMedium))
                    .padding(.horizontal)
            }
        }
    }

    // MARK: - Header Variants

    private var leadingHeader: some View {
        HStack {
            if title != nil || subtitle != nil {
                VStack(alignment: .leading, spacing: 4) {
                    if let title = title {
                        Text(title)
                            .font(titleFont)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                    }

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(subtitleFont)
                            .foregroundColor(DesignTokens.Colors.textSubtle)
                    }
                }
            }

            Spacer()

            closeButton
        }
        .padding(.top, DesignTokens.Spacing.card)
        .padding(.horizontal)
        .padding(.bottom, DesignTokens.Spacing.component)
    }

    private var centeredHeader: some View {
        HStack {
            closeButton

            Spacer()

            VStack(spacing: 4) {
                if let title = title {
                    Text(title)
                        .font(titleFont)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                }

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(subtitleFont)
                        .foregroundColor(DesignTokens.Colors.textSubtle)
                }
            }

            Spacer()

            // Placeholder for symmetry
            Color.clear.frame(width: 40)
        }
        .padding(.top, DesignTokens.Spacing.card)
        .padding(.horizontal)
        .padding(.bottom, DesignTokens.Spacing.component)
    }

    private var closeButton: some View {
        Button {
            isPresented = false
        } label: {
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(DesignTokens.Colors.textSubtle)
                .font(.title2)
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        // Simple close button only
        ModalHeader(isPresented: .constant(true))
            .background(Color.black)

        // Title only
        ModalHeader(isPresented: .constant(true), title: "Settings")
            .background(Color.black)

        // Title + subtitle (leading)
        ModalHeader(
            isPresented: .constant(true),
            title: "Open in App",
            subtitle: "Launch the app to complete action"
        )
        .background(Color.black)

        // Centered title + subtitle
        ModalHeader(
            isPresented: .constant(true),
            title: "Attachments",
            subtitle: "3 files",
            alignment: .center
        )
        .background(Color.black)

        // With divider
        ModalHeader(
            isPresented: .constant(true),
            title: "Account",
            subtitle: "Manage your preferences",
            showDivider: true
        )
        .background(Color.black)
    }
}

// MARK: - Migration Notes

/*
 WEEK 6 REFACTORING: ModalHeader Consolidation

 This component replaces 46 duplicate modal header implementations:

 BEFORE (in every modal):
 -----------------------
 HStack {
     Spacer()
     Button {
         isPresented = false
     } label: {
         Image(systemName: "xmark.circle.fill")
             .foregroundColor(DesignTokens.Colors.textSubtle)
             .font(.title2)
     }
 }
 .padding()

 AFTER:
 ------
 ModalHeader(isPresented: $isPresented)

 Benefits:
 ---------
 1. Single source of truth for modal header styling
 2. Consistent close button behavior across all modals
 3. Easy to add new features (e.g., back button, title)
 4. Reduces ~15 lines per modal = 690 lines eliminated
 5. Type-safe API with customization options

 Customization Options:
 ----------------------
 - title: Optional title text (default: nil)
 - subtitle: Optional subtitle text (default: nil)
 - alignment: .leading or .center (default: .leading)
 - showDivider: Show divider below header (default: false)
 - titleFont: Custom title font (default: .title2.bold())
 - subtitleFont: Custom subtitle font (default: .subheadline)

 Files Using This Component:
 ---------------------------
 (Updated during Phase 2 of Week 6 refactoring)
 - PayInvoiceModal.swift
 - TrackPackageModal.swift
 - AddToCalendarModal.swift
 - ... (43 more modals)

 Future Enhancements:
 --------------------
 1. Add back button support for multi-step flows
 2. Add action buttons (e.g., "Save", "Done")
 3. Add progress indicator for multi-step modals
 4. Add accessibility labels
 5. Add haptic feedback on close
 */
