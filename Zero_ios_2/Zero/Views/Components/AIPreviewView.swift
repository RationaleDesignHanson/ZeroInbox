import SwiftUI

/// AI Preview section with star badge header matching new card design
/// Shows AI Analysis header, structured summary sections, and expand/collapse
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

    // Star badge gradient colors
    private var starBadgeGradient: [Color] {
        card.type == .ads ? [
            Color.yellow.opacity(0.9),
            Color.orange.opacity(0.8)
        ] : [
            Color.yellow.opacity(0.9),
            Color.orange.opacity(0.8)
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.element) {
            // AI ANALYSIS Header with Star Badge
            HStack(spacing: DesignTokens.Spacing.inline) {
                // Star badge
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: starBadgeGradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 24, height: 24)

                    Image(systemName: "star.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }

                Text("AI ANALYSIS")
                    .font(DesignTokens.Typography.aiAnalysisTitle)
                    .foregroundColor(headerTextColorStrong)
                    .tracking(0.5)

                Spacer()
            }

            // AI Summary Content with structured sections
            StructuredSummaryView(card: card, lineLimit: isExpanded ? nil : 4)
                .onTapGesture {
                    withAnimation(DesignTokens.Animation.Spring.snappy) {
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
        .padding(DesignTokens.AIAnalysisBox.padding)
        .background(
            // Gradient background: purple for mail, teal for ads
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
        .cornerRadius(DesignTokens.AIAnalysisBox.radius)
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.AIAnalysisBox.radius)
                .strokeBorder(
                    card.type == .ads ?
                        DesignTokens.Colors.adsGradientEnd.opacity(0.4) :
                        Color.purple.opacity(0.4),
                    lineWidth: DesignTokens.AIAnalysisBox.borderWidth
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
