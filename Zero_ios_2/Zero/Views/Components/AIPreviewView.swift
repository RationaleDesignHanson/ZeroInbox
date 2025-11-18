import SwiftUI

/// AI Preview section with purple gradient header matching web demo design
/// Shows AI intelligence header, confidence, and summary (no action badges - use swipe up for actions)
struct AIPreviewView: View {
    let card: EmailCard

    @State private var isExpanded: Bool = false

    // Conditional text colors based on card type
    private var headerTextColor: Color {
        card.type == .ads ? DesignTokens.Colors.adsTextSecondary : Color.white.opacity(DesignTokens.Opacity.textTertiary)
    }

    private var headerTextColorStrong: Color {
        card.type == .ads ? DesignTokens.Colors.adsTextPrimary : Color.white.opacity(DesignTokens.Opacity.textSecondary)
    }

    private var progressBarBackground: Color {
        card.type == .ads ? DesignTokens.Colors.adsTextSubtle.opacity(DesignTokens.Opacity.overlayMedium) : Color.white.opacity(DesignTokens.Opacity.overlayLight)
    }

    private var progressBarFill: Color {
        card.type == .ads ? DesignTokens.Colors.adsTextPrimary : Color.white
    }

    var body: some View {
        // Single unified container matching web demo - purple gradient background
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.component) {
            // Analysis Confidence Header with Progress Bar
            VStack(alignment: .leading, spacing: 6) {
                // Label and percentage on one row
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(headerTextColor)

                    Text("Analysis Confidence")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(headerTextColor)

                    Spacer()

                    if let confidence = card.intentConfidence {
                        Text("\(Int(confidence * 100))%")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(headerTextColorStrong)
                    }
                }

                // Percentage bar
                if let confidence = card.intentConfidence {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background bar
                            RoundedRectangle(cornerRadius: 3)
                                .fill(progressBarBackground)
                                .frame(height: 6)

                            // Filled percentage
                            RoundedRectangle(cornerRadius: 3)
                                .fill(progressBarFill)
                                .frame(width: geometry.size.width * CGFloat(confidence), height: 6)
                        }
                    }
                    .frame(height: 6)
                }
            }
            .padding(.bottom, 4)

            // AI Summary Content - directly inside same container (no separate box)
            // Tap to expand/collapse
            StructuredSummaryView(card: card, lineLimit: isExpanded ? nil : 3)
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                    HapticService.shared.lightImpact()
                }

            // Expansion indicator
            if !isExpanded {
                HStack {
                    Spacer()
                    Text("Tap to expand")
                        .font(.caption2)
                        .foregroundColor(headerTextColor)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(headerTextColor)
                }
            }
        }
        .padding(DesignTokens.Spacing.component)
        .background(
            // Gradient background: purple for mail, green for ads
            // Ads use higher opacity (0.35/0.25) for better contrast on light card background
            LinearGradient(
                colors: card.type == .ads ? [
                    DesignTokens.Colors.adsGradientStart.opacity(0.35),
                    DesignTokens.Colors.adsGradientEnd.opacity(0.25)
                ] : [
                    Color.purple.opacity(DesignTokens.Opacity.overlayLight),
                    Color.purple.opacity(0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(DesignTokens.Radius.button)
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                .strokeBorder(
                    card.type == .ads ?
                        DesignTokens.Colors.adsGradientEnd.opacity(0.4) :
                        Color.purple.opacity(0.4),
                    lineWidth: 1.5
                )
        )
    }
}

// MARK: - Preview

#Preview("AI Preview with Actions") {
    let card = EmailCard(
        id: "preview-1",
        type: .mail,
        state: .unseen,
        priority: .high,
        hpa: "Sign & Send",
        timeAgo: "2h ago",
        title: "Field Trip Permission Form",
        summary: """
        **Actions:**
        • Sign permission form by Wednesday 5 PM
        • Pay $25 trip fee online

        **Why:**
        Emma's class needs signed approval for Natural History Museum field trip this Friday.

        **Context:**
        • Trip includes dinosaur exhibits and planetarium show
        • Pack lunch and water bottle
        """,
        body: nil,
        htmlBody: nil,
        metaCTA: "Swipe Right: Sign & Send",
        intent: "education.permission.form",
        intentConfidence: 0.95,
        suggestedActions: [
            EmailAction(
                actionId: "sign_form",
                displayName: "Sign & Send",
                actionType: .inApp,
                isPrimary: true,
                priority: 1
            ),
            EmailAction(
                actionId: "add_to_calendar",
                displayName: "Add to Calendar",
                actionType: .inApp,
                isPrimary: false,
                priority: 2
            ),
            EmailAction(
                actionId: "view_details",
                displayName: "View Details",
                actionType: .goTo,
                isPrimary: false,
                priority: 3
            )
        ],
        sender: SenderInfo(name: "Mrs. Johnson", initial: "J", email: "teacher@school.edu")
    )

    ZStack {
        LinearGradient(
            colors: [Color.blue, Color.purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        AIPreviewView(card: card)
        .padding()
    }
}
