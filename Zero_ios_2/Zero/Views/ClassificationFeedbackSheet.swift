//
//  ClassificationFeedbackSheet.swift
//  Zero
//
//  Created by Claude Code on 10/25/25.
//

import SwiftUI

/**
 * ClassificationFeedbackSheet - Modal for classification feedback and support
 *
 * Allows users to:
 * 1. Switch email category (Mail ↔ Ads)
 * 2. Report other issues through in-app support form
 */
struct ClassificationFeedbackSheet: View {
    let card: EmailCard
    let onCategorySwitch: (CardType) -> Void

    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @State private var showReportIssue = false

    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: DesignTokens.Spacing.card) {
                        // Header
                        VStack(spacing: DesignTokens.Spacing.component) {
                            Image(systemName: "questionmark.circle.fill")
                                .font(.system(size: 56))
                                .foregroundColor(.blue)
                                .padding(.top, DesignTokens.Spacing.card)

                            Text("Email Classification")
                                .font(.title2.bold())
                                .foregroundColor(textColor)

                            Text("Help us improve by providing feedback")
                                .font(.subheadline)
                                .foregroundColor(textColor.opacity(DesignTokens.Opacity.textDisabled))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }

                        // Current classification
                        VStack(spacing: DesignTokens.Spacing.component) {
                            Text("Current Category")
                                .font(.caption.bold())
                                .foregroundColor(textColor.opacity(DesignTokens.Opacity.textDisabled))
                                .textCase(.uppercase)

                            HStack(spacing: DesignTokens.Spacing.inline) {
                                Image(systemName: categoryIcon(for: card.type))
                                    .font(.title2)
                                    .foregroundColor(categoryColor(for: card.type))

                                Text(card.type.displayName)
                                    .font(.title3.bold())
                                    .foregroundColor(textColor)
                            }
                            .padding(.horizontal, DesignTokens.Spacing.card)
                            .padding(.vertical, DesignTokens.Spacing.component)
                            .background(categoryColor(for: card.type).opacity(0.15))
                            .cornerRadius(DesignTokens.Radius.button)
                        }
                        .padding(.horizontal)

                        Divider()
                            .padding(.horizontal)

                        // Action buttons
                        VStack(spacing: DesignTokens.Spacing.section) {
                            // Switch category button
                            Button {
                                switchCategory()
                            } label: {
                                HStack(spacing: DesignTokens.Spacing.component) {
                                    Image(systemName: "arrow.left.arrow.right.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.blue)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Switch to \(oppositeCategory.displayName)")
                                            .font(.headline)
                                            .foregroundColor(textColor)

                                        Text("Reclassify this email as \(oppositeCategory.displayName)")
                                            .font(.caption)
                                            .foregroundColor(textColor.opacity(DesignTokens.Opacity.textDisabled))
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(textColor.opacity(DesignTokens.Opacity.overlayMedium))
                                }
                                .padding(DesignTokens.Spacing.section)
                                .background(rowBackgroundColor)
                                .cornerRadius(DesignTokens.Radius.button)
                            }
                            .buttonStyle(PlainButtonStyle())

                            // Report issue button
                            Button {
                                showReportIssue = true
                            } label: {
                                HStack(spacing: DesignTokens.Spacing.component) {
                                    Image(systemName: "exclamationmark.bubble.fill")
                                        .font(.title2)
                                        .foregroundColor(.orange)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Report Other Issue")
                                            .font(.headline)
                                            .foregroundColor(textColor)

                                        Text("Send feedback to our support team")
                                            .font(.caption)
                                            .foregroundColor(textColor.opacity(DesignTokens.Opacity.textDisabled))
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(textColor.opacity(DesignTokens.Opacity.overlayMedium))
                                }
                                .padding(DesignTokens.Spacing.section)
                                .background(rowBackgroundColor)
                                .cornerRadius(DesignTokens.Radius.button)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal)

                        Spacer()
                    }
                }
            }
            .navigationTitle("Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
            .sheet(isPresented: $showReportIssue) {
                ReportIssueView(card: card)
            }
        }
    }

    // MARK: - Helpers

    private var oppositeCategory: CardType {
        let modern = card.type
        return modern == .mail ? .ads : .mail
    }

    private func switchCategory() {
        HapticService.shared.mediumImpact()
        onCategorySwitch(oppositeCategory)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            presentationMode.wrappedValue.dismiss()
        }
    }

    private func categoryIcon(for type: CardType) -> String {
        let modern = type
        return modern == .mail ? "envelope.fill" : "megaphone.fill"
    }

    private func categoryColor(for type: CardType) -> Color {
        let modern = type
        return modern == .mail ? Color.blue : Color.orange
    }

    // MARK: - Computed Colors

    private var backgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.10) : Color(white: 0.95)
    }

    private var textColor: Color {
        colorScheme == .dark ? Color.white : Color.black
    }

    private var rowBackgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.15) : Color.white
    }
}

// MARK: - Report Issue View

struct ReportIssueView: View {
    let card: EmailCard

    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @State private var issueDescription = ""
    @State private var isSubmitting = false
    @State private var showSuccess = false

    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.ignoresSafeArea()

                if showSuccess {
                    successView
                } else {
                    formView
                }
            }
            .navigationTitle("Report Issue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }

    // MARK: - Subviews

    private var formView: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.card) {
                // Header
                VStack(spacing: DesignTokens.Spacing.component) {
                    Image(systemName: "exclamationmark.bubble.fill")
                        .font(.system(size: 56))
                        .foregroundColor(.orange)
                        .padding(.top, DesignTokens.Spacing.card)

                    Text("Report an Issue")
                        .font(.title2.bold())
                        .foregroundColor(textColor)

                    Text("Describe the problem you're experiencing")
                        .font(.subheadline)
                        .foregroundColor(textColor.opacity(DesignTokens.Opacity.textDisabled))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                // Email context
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.inline) {
                    Text("Email Details")
                        .font(.caption.bold())
                        .foregroundColor(textColor.opacity(DesignTokens.Opacity.textDisabled))
                        .textCase(.uppercase)

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("From:")
                                .font(.caption)
                                .foregroundColor(textColor.opacity(DesignTokens.Opacity.textDisabled))
                            Text(card.sender?.email ?? "Unknown")
                                .font(.caption)
                                .foregroundColor(textColor)
                        }

                        HStack {
                            Text("Subject:")
                                .font(.caption)
                                .foregroundColor(textColor.opacity(DesignTokens.Opacity.textDisabled))
                            Text(card.title)
                                .font(.caption)
                                .foregroundColor(textColor)
                                .lineLimit(1)
                        }
                    }
                    .padding(DesignTokens.Spacing.component)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(rowBackgroundColor)
                    .cornerRadius(DesignTokens.Spacing.inline)
                }
                .padding(.horizontal)

                // Issue description
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.component) {
                    Text("Describe the Issue")
                        .font(.headline)
                        .foregroundColor(textColor)

                    TextEditor(text: $issueDescription)
                        .font(.body)
                        .foregroundColor(textColor)
                        .frame(height: 150)
                        .padding(DesignTokens.Spacing.inline)
                        .background(inputBackgroundColor)
                        .cornerRadius(DesignTokens.Spacing.inline)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.Spacing.inline)
                                .strokeBorder(borderColor, lineWidth: 1)
                        )

                    Text("Please include as much detail as possible")
                        .font(.caption)
                        .foregroundColor(textColor.opacity(DesignTokens.Opacity.overlayStrong))
                }
                .padding(.horizontal)

                // Submit button
                Button {
                    submitIssue()
                } label: {
                    HStack {
                        if isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Label("Submit Report", systemImage: "paperplane.fill")
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignTokens.Spacing.section)
                    .background(
                        LinearGradient(
                            colors: canSubmit ? [Color.blue, Color.cyan] : [Color.gray, Color.gray],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(DesignTokens.Radius.button)
                }
                .disabled(!canSubmit || isSubmitting)
                .padding(.horizontal)

                Spacer()
            }
        }
    }

    private var successView: some View {
        VStack(spacing: DesignTokens.Spacing.card) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundColor(.green)

            Text("Report Submitted")
                .font(.title2.bold())
                .foregroundColor(textColor)

            Text("Thank you for your feedback! Our team will review your report.")
                .font(.body)
                .foregroundColor(textColor.opacity(DesignTokens.Opacity.textDisabled))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                presentationMode.wrappedValue.dismiss()
            } label: {
                Text("Done")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignTokens.Spacing.section)
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color.cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(DesignTokens.Radius.button)
            }
            .padding(.horizontal, 40)
        }
    }

    // MARK: - Actions

    private func submitIssue() {
        guard !issueDescription.isEmpty else { return }

        isSubmitting = true
        HapticService.shared.mediumImpact()

        Task {
            do {
                try await FeedbackService.shared.submitIssueReport(
                    emailId: card.id,
                    emailFrom: card.sender?.email,
                    emailSubject: card.title,
                    issueDescription: issueDescription
                )

                await MainActor.run {
                    isSubmitting = false
                    withAnimation {
                        showSuccess = true
                    }
                    HapticService.shared.success()
                }

                Logger.info("✅ Issue report submitted for email: \(card.id)", category: .ui)

            } catch {
                await MainActor.run {
                    isSubmitting = false
                }
                Logger.error("Failed to submit issue report: \(error.localizedDescription)", category: .network)
            }
        }
    }

    // MARK: - Computed Properties

    private var canSubmit: Bool {
        !issueDescription.isEmpty && issueDescription.count >= 10
    }

    private var backgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.10) : Color(white: 0.95)
    }

    private var inputBackgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.15) : Color.white
    }

    private var textColor: Color {
        colorScheme == .dark ? Color.white : Color.black
    }

    private var rowBackgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.15) : Color.white
    }

    private var borderColor: Color {
        colorScheme == .dark ? Color.white.opacity(DesignTokens.Opacity.glassLight) : Color.black.opacity(DesignTokens.Opacity.glassUltraLight)
    }
}

#Preview {
    ClassificationFeedbackSheet(
        card: EmailCard(
            id: "1",
            type: .mail,
            state: .unseen,
            priority: .high,
            hpa: "Sign & Send",
            timeAgo: "2h ago",
            title: "Field Trip Permission",
            summary: "Please sign the permission form",
            metaCTA: "Sign & Send"
        ),
        onCategorySwitch: { _ in }
    )
}
