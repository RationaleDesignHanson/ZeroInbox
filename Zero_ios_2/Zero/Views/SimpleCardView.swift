import SwiftUI

struct SimpleCardView: View {
    let card: EmailCard
    let isTopCard: Bool
    var revealProgress: Double = 0.0
    var onSignatureTap: (() -> Void)? = nil
    var onThreadTap: (() -> Void)? = nil // Callback for thread indicator tap
    @ObservedObject var viewModel: EmailViewModel // Changed to @ObservedObject to react to changes
    var isSaved: Bool = false // Whether this deal is saved
    var hasMultipleAccounts: Bool = false // Whether user has multiple email accounts
    var cardIndex: Int = 0 // Card position in stack (for showing hints on first cards)
    @State private var showingDetail = false
    @State private var showingPriorityPicker = false
    @State private var showingClassificationMenu = false
    @State private var animationComplete = false // Tracks if cycling hint animation finished
    @State private var currentActionLabel: String = ""
    @State private var previousActionId: String = "" // Track previous action ID for change detection
    @AppStorage("showModeIndicators") private var showModeIndicators: Bool = true // Status dots visibility

    // Computed property for effective action ID
    private var effectiveActionId: String {
        return viewModel.getEffectiveAction(for: card)
    }

    // Helper function to update action label
    private func updateActionLabel() {
        let actionId = viewModel.getEffectiveAction(for: card)
        currentActionLabel = viewModel.getActionLabel(for: actionId)
        previousActionId = actionId // Store for next comparison
    }

    // Show animated hint on first card only (before it completes)
    private var shouldShowAnimatedHint: Bool {
        let hasSeenHint = UserDefaults.standard.bool(forKey: "hasSeenFirstCardHint")
        return !hasSeenHint && cardIndex == 0 && isTopCard && !animationComplete
    }

    // Show static CTA on all cards EXCEPT first card during animation
    private var shouldShowStaticCTA: Bool {
        let hasSeenHint = UserDefaults.standard.bool(forKey: "hasSeenFirstCardHint")

        // First card: show after animation completes OR if user has seen hint before
        if cardIndex == 0 && isTopCard {
            return hasSeenHint || animationComplete
        }

        // All other cards: always show
        return true
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.section) {  // Optimized for dense content cards
            // HEADER - Universal for all cards
            HStack(alignment: .top, spacing: DesignTokens.Spacing.component) {
                // Left: Square View button (spans height of name+time rows)
                squareViewButton

                // Center-Left: Name and time
                VStack(alignment: .leading, spacing: 2) {
                    Text(displayName)
                        .font(.headline)
                        .foregroundColor(DesignTokens.Colors.textPrimary)

                    // Recipient email (only show when multiple accounts)
                    if hasMultipleAccounts, let recipientEmail = card.recipientEmail {
                        Text(recipientEmail)
                            .font(.caption2)
                            .foregroundColor(DesignTokens.Colors.textSubtle)
                    }

                    Text(card.timeAgo)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()

                // Top right: Priority badge + Status indicators
                HStack(spacing: 8) {
                    Button {
                        showingPriorityPicker = true
                    } label: {
                        priorityBadge
                    }

                    // Minimal status indicators - 4 most critical, larger for visibility
                    HStack(spacing: DesignTokens.Spacing.inline) {
                        if showModeIndicators {
                            // VIP indicator - gold dot (increased size for visibility)
                            if card.isVIP == true {
                                Circle()
                                    .fill(Color.yellow.opacity(0.9))
                                    .frame(width: 12, height: 12)
                                    .shadow(color: Color.yellow.opacity(0.5), radius: 2)
                            }

                            // Deadline indicator - colored dot by urgency (increased size)
                            if let deadline = card.deadline {
                                Circle()
                                    .fill(deadline.isUrgent ? Color.red : (deadline.value ?? 0) <= 3 ? Color.orange : Color.green)
                                    .frame(width: 12, height: 12)
                                    .shadow(color: (deadline.isUrgent ? Color.red : Color.orange).opacity(0.5), radius: 2)
                            }

                            // Shopping indicator - green dot (increased size)
                            if card.isShoppingEmail == true {
                                Circle()
                                    .fill(Color.green.opacity(0.9))
                                    .frame(width: 12, height: 12)
                                    .shadow(color: Color.green.opacity(0.5), radius: 2)
                            }

                            // Attachment indicator - blue dot (increased size)
                            if card.hasAttachments == true {
                                Circle()
                                    .fill(Color.blue.opacity(0.9))
                                    .frame(width: 12, height: 12)
                                    .shadow(color: Color.blue.opacity(0.5), radius: 2)
                            }
                        }

                        if isSaved {
                            Image(systemName: "bookmark.fill")
                                .foregroundColor(.orange)
                                .font(.title3)
                        }
                    }
                }
            }

            // Urgency indicator - shown prominently under sender info
            if card.urgent == true, let expiresIn = card.expiresIn {
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.white)
                    Text("Expires in \(expiresIn)")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                }
                .padding(.horizontal, DesignTokens.Spacing.component)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.2))
                .cornerRadius(DesignTokens.Radius.chip)
            }

            // CONTENT

            // Title (reduced to 80% of original size)
            Text(card.title)
                .font(DesignTokens.Typography.cardTitle)
                .foregroundColor(DesignTokens.Colors.textPrimary)
                .shadow(color: .black.opacity(0.3), radius: 2, y: 1)

            // Email Summary Text - Preview text between title and AI analysis (matches web demo)
            if !card.summary.isEmpty {
                Text(parseMarkdown(card.summary))
                    .font(.system(size: 15))
                    .foregroundColor(Color.white.opacity(0.85))
                    .lineSpacing(2.0) // Increased from 1.5 for better readability
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
            }

            // Product image (shopping only) - appears after title
            if let imageUrl = card.productImageUrl {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 140)  // Increased from 100px for better product detail visibility
                        .clipped()
                        .cornerRadius(DesignTokens.Radius.button)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 140)
                        .cornerRadius(DesignTokens.Radius.button)
                }
                .padding(.top, 4)
                .padding(.bottom, hasPricing ? 0 : 8) // Extra spacing when no pricing follows
            }

            // AI Preview Section (liquid glass with streamlined header)
            AIPreviewView(card: card)
                .padding(.top, 8)

            // Metrics panel (sales only)
            if let value = card.value, let probability = card.probability, let score = card.score {
                HStack(spacing: DesignTokens.Spacing.section) {
                    VStack(spacing: 4) {
                        Text("\(score)")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        Text("Lead Score")
                            .font(.caption2)
                            .foregroundColor(DesignTokens.Colors.textSubtle)
                    }

                    VStack(spacing: 4) {
                        Text(value)
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        Text("Deal Value")
                            .font(.caption2)
                            .foregroundColor(DesignTokens.Colors.textSubtle)
                    }

                    VStack(spacing: 4) {
                        Text("\(probability)%")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        Text("Close Rate")
                            .font(.caption2)
                            .foregroundColor(DesignTokens.Colors.textSubtle)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(DesignTokens.Radius.button)
            }

            // Pricing (shopping only) - MUST come BEFORE action button for ADS cards per design system
            if let salePrice = card.salePrice, let originalPrice = card.originalPrice {
                HStack(spacing: DesignTokens.Spacing.component) {
                    Text("$\(String(format: "%.0f", salePrice))")
                        .font(.system(size: 24, weight: .bold))  // 60% of largeTitle (~40px) = 24px
                        .foregroundColor(.white)

                    Text("$\(String(format: "%.0f", originalPrice))")
                        .font(.system(size: 17, weight: .regular))  // 60% of title2 (~28px) = 17px
                        .foregroundColor(.white.opacity(0.5))
                        .strikethrough()

                    if let discount = card.discount {
                        Text("\(discount)% OFF")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, DesignTokens.Spacing.component)
                            .padding(.vertical, 6)
                            .background(Color.green.opacity(0.9))  // Match design system green badge
                            .cornerRadius(DesignTokens.Radius.chip)
                    }
                }
                .padding(.top, DesignTokens.Spacing.inline)
            }

            // Progressive reveal: Animated hint → Static CTA
            // Positioned AFTER pricing for shopping emails
            if shouldShowAnimatedHint {
                // First card: Show animated cycling hint teaching all 4 directions
                SwipeHintOverlay(
                    actionLabel: currentActionLabel,
                    onComplete: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            animationComplete = true
                        }
                        // Mark as seen so subsequent app launches skip animation
                        UserDefaults.standard.set(true, forKey: "hasSeenFirstCardHint")
                    }
                )
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
            } else if shouldShowStaticCTA {
                // All other cards + first card after animation: Swipe-focused track design
                // Horizontal layout with directional cues matching holographic design system
                HStack(spacing: 0) {
                    // Left: Directional chevrons (swipe indicator)
                    HStack(spacing: 2) {
                        ForEach(0..<3, id: \.self) { _ in
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .padding(.leading, 16)

                    Spacer()

                    // Right: Action label
                    Text(currentActionLabel)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.trailing, 16)
                }
                .frame(height: 48)
                .background(
                    ZStack {
                        // Glass morphism base (matches card design system)
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial.opacity(0.3))

                        // Holographic rim (matches bottom nav design)
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.cyan.opacity(0.4),
                                        Color.blue.opacity(0.5),
                                        Color.purple.opacity(0.4),
                                        Color.pink.opacity(0.3)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 1.5
                            )

                        // Animated shimmer sweep (swipe motion cue)
                        SwipeShimmer()

                        // Right edge glow (directional cue for swipe direction)
                        HStack {
                            Spacer()
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    Color.cyan.opacity(0.2)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(width: 60)
                        }
                    }
                )
                .padding(.top, DesignTokens.Spacing.component)
                .transition(.opacity)
            }
        }
        .padding(DesignTokens.Spacing.section)
        .padding(.top, 4)  // Reduced from 8 to prevent header crop on dense cards
        .padding(.bottom, DesignTokens.Spacing.section) // Ensure bottom padding
        .frame(width: UIScreen.main.bounds.width - 48)
        .frame(maxHeight: UIScreen.main.bounds.height - 180, alignment: .top)
        // maxHeight prevents overflow past bottom nav (accounts for status bar ~50px + bottom nav ~90px + spacing ~40px)
        // alignment: .top ensures cards are top-aligned and size to fit content dynamically
        .background(
            ZStack {
                // Rich visual background (nebula for MAIL, scenic for ADS)
                RichCardBackground(for: card.type, animationSpeed: 30)

                // Ultra-thin liquid glass material overlay (Apple's design guideline)
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .opacity(0.3)
            }
        )
        .overlay(shimmerOverlay)
        .overlay(stackOverlay)
        .overlay(classificationFeedbackButton, alignment: .bottomLeading)
        .cornerRadius(DesignTokens.Radius.card)
        .shadow(color: .black.opacity(0.3), radius: 20)
        .opacity(isTopCard ? 1.0 : max(0.85, min(revealProgress + 0.85, 0.95)))
        .blur(radius: isTopCard ? 0 : max(0, 1 - (revealProgress * 2)))
        .onAppear {
            // Initialize action label
            updateActionLabel()

            // DEBUG: Reset animated hint flag for testing
            // This allows developers to see the animation every time during development
            #if DEBUG
            if cardIndex == 0 {
                UserDefaults.standard.removeObject(forKey: "hasSeenFirstCardHint")
                Logger.info("🔄 Reset animated hint flag for first card (DEBUG mode)", category: .ui)
            }
            #endif
        }
        .onChange(of: effectiveActionId) { oldValue, newValue in
            // Update label when effective action changes for this card
            Logger.info("🔄 Action changed for card \(card.id): \(oldValue) → \(newValue)", category: .ui)
            updateActionLabel()
        }
        .onReceive(viewModel.objectWillChange) { _ in
            // Listen to viewModel changes (includes userPreferences changes)
            // This catches when customActions dictionary updates via the forwarded publisher
            let newActionId = viewModel.getEffectiveAction(for: card)
            if newActionId != previousActionId {
                Logger.info("🔄 ViewModel changed, updating label for card \(card.id): \(previousActionId) → \(newActionId)", category: .ui)
                updateActionLabel()
            }
        }
    }
    
    // MARK: - Computed Properties

    /// Determines if this email is "shoppable" - can be directly added to cart
    var isShoppable: Bool {
        // Shoppable if it's a deal_stacker AND has complete pricing data
        return card.type == .ads &&
               card.salePrice != nil &&
               card.productImageUrl != nil
    }

    /// Check if card has pricing information
    var hasPricing: Bool {
        return card.salePrice != nil || card.originalPrice != nil
    }

    /// Dynamic line limit for summary based on card type
    var summaryLineLimit: Int? {
        // Return nil to allow flexible summary length based on content
        // This allows the AI-generated summaries to show their full structured content
        return nil
    }

    /// Parse markdown in summary text for rich formatting (bold, italic, links, etc.)
    private func parseMarkdown(_ text: String) -> AttributedString {
        do {
            // Parse markdown with inline-only syntax (no block elements like headers)
            let options = AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .inlineOnlyPreservingWhitespace
            )
            return try AttributedString(markdown: text, options: options)
        } catch {
            // Fallback to plain text if markdown parsing fails
            Logger.warning("Failed to parse markdown in summary: \(error.localizedDescription)", category: .ui)
            return AttributedString(text)
        }
    }

    // MARK: - Computed Views

    var displayName: String {
        card.kid?.name ?? card.company?.name ?? card.sender?.name ?? card.store ?? card.airline ?? "Email"
    }

    var priorityBadge: some View {
        Group {
            switch card.priority {
            case .critical:
                Text("CRITICAL")
                    .font(.caption2)
                    .fontWeight(.heavy)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.red.opacity(0.9))
                    .cornerRadius(DesignTokens.Radius.minimal)
            case .high:
                Text("HIGH")
                    .font(.caption2)
                    .fontWeight(.heavy)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.orange.opacity(0.9))
                    .cornerRadius(DesignTokens.Radius.minimal)
            case .medium:
                Text("MEDIUM")
                    .font(.caption2)
                    .fontWeight(.heavy)
                    .foregroundColor(.black)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.yellow.opacity(0.9))
                    .cornerRadius(DesignTokens.Radius.minimal)
            case .low:
                Text("LOW")
                    .font(.caption2)
                    .fontWeight(.heavy)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.green.opacity(0.9))
                    .cornerRadius(DesignTokens.Radius.minimal)
            }
        }
    }
    
    var squareViewButton: some View {
        Button {
            // If email is part of a thread, show thread view; otherwise show single email detail
            if let threadLength = card.threadLength, threadLength > 1 {
                onThreadTap?()
            } else {
                showingDetail = true
            }
        } label: {
            VStack(spacing: 4) {
                // Show thread icon if this email is part of a thread
                if let threadLength = card.threadLength, threadLength > 1 {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                    Text("\(threadLength)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.85))
                } else {
                    Image(systemName: "envelope.open.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                }

                Text("View")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
            }
            .frame(width: 56, height: 56)
            .background(Color.white.opacity(0.25))
            .cornerRadius(DesignTokens.Radius.button)
        }
        .sheet(isPresented: $showingDetail) {
            EmailDetailView(card: card)
        }
        .sheet(isPresented: $showingPriorityPicker) {
            PriorityPickerView(
                selectedPriority: Binding(
                    get: { card.priority },
                    set: { newPriority in
                        viewModel.updateCardPriority(cardId: card.id, priority: newPriority)
                        Logger.info("✅ Updated card priority to: \(newPriority.displayName)", category: .ui)
                    }
                ),
                onSelect: { priority in
                    viewModel.updateCardPriority(cardId: card.id, priority: priority)
                    HapticService.shared.success()
                }
            )
        }
    }

    @ViewBuilder
    var shimmerOverlay: some View {
        if isShoppable {
            HolographicShimmer()
                .opacity(isTopCard ? 0.3 : 0)
        }
    }

    var stackOverlay: some View {
        Color.black.opacity(isTopCard ? 0 : 0.15)
    }
    
    var archetypeBadge: some View {
        HStack(spacing: 3) {
            Image(systemName: archetypeIcon)
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.9))
            Text(card.type.displayName.uppercased())
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 3)
        .background(Color.white.opacity(0.15))
        .cornerRadius(4)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(Color.white.opacity(0.3), lineWidth: 0.5)
        )
    }
    
    var archetypeIcon: String {
        let modern = card.type
        switch modern {
        case .mail: return "envelope.fill"
        case .ads: return "cart.fill"
        }
    }

    /// Handle action badge tap - route to appropriate modal or action
    private func handleActionBadgeTap(action: EmailAction) {
        Logger.info("🎬 Action badge tapped: \(action.displayName) (\(action.actionId))", category: .ui)

        switch action.actionType {
        case .inApp:
            // Show in-app modal (signature, payment, etc.)
            // Trigger the existing onSignatureTap callback to show action modal
            if action.actionId.contains("sign") {
                onSignatureTap?()
            } else {
                // For other in-app actions, we can show a generic modal
                onSignatureTap?()
            }

        case .goTo:
            // Open URL (if context has url)
            if let context = action.context,
               let urlString = context["url"] ?? context["storeUrl"],
               let url = URL(string: urlString) {
                UIApplication.shared.open(url)
                Logger.info("🌐 Opening URL: \(urlString)", category: .ui)
            }
        }
    }

    /// Classification feedback button - bottom-left corner
    var classificationFeedbackButton: some View {
        Button {
            showingClassificationMenu = true
        } label: {
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.white.opacity(0.7))
                .background(
                    Circle()
                        .fill(Color.black.opacity(0.3))
                        .frame(width: 32, height: 32)
                )
        }
        .padding(DesignTokens.Spacing.section)
        .sheet(isPresented: $showingClassificationMenu) {
            ClassificationFeedbackSheet(
                card: card,
                onCategorySwitch: { newCategory in
                    Task {
                        do {
                            try await FeedbackService.shared.submitClassificationFeedback(
                                emailId: card.id,
                                originalCategory: card.type.displayName,
                                correctedCategory: newCategory.displayName
                            )
                            Logger.info("✅ Classification feedback sent: \(card.type.displayName) → \(newCategory.displayName)", category: .ui)
                            HapticService.shared.success()
                        } catch {
                            Logger.error("Failed to submit classification feedback: \(error.localizedDescription)", category: .network)
                        }
                    }
                }
            )
        }
    }

}

// MARK: - Previews

#Preview("MAIL Card - School Permission") {
    let viewModel = EmailViewModel(
        userPreferences: UserPreferencesService(),
        appState: AppStateManager(),
        cardManagement: CardManagementService()
    )

    SimpleCardView(
        card: EmailCard(
            id: "preview-mail-1",
            type: .mail,
            state: .unseen,
            priority: .high,
            hpa: "Sign & Send",
            timeAgo: "2h ago",
            title: "Field Trip Permission Form",
            summary: "Please sign the attached permission form for the upcoming Science Museum field trip on October 25th. Fee: $15 per student.",
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
                    priority: 1,
                    context: ["formName": "Field Trip Permission"],
                    isCompound: true,
                    compoundSteps: ["sign_form", "pay_form_fee"]
                ),
                EmailAction(
                    actionId: "add_to_calendar",
                    displayName: "Add to Calendar",
                    actionType: .inApp,
                    isPrimary: false,
                    priority: 2,
                    context: ["eventDate": "Oct 25"]
                )
            ],
            sender: SenderInfo(name: "Mrs. Johnson", initial: "J", email: "teacher@school.edu"),
            requiresSignature: true,
            isSchoolEmail: true,
            teacher: "Mrs. Johnson",
            school: "Lincoln Elementary"
        ),
        isTopCard: true,
        viewModel: viewModel
    )
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black)
}

#Preview("ADS Card - Shopping Deal") {
    let viewModel = EmailViewModel(
        userPreferences: UserPreferencesService(),
        appState: AppStateManager(),
        cardManagement: CardManagementService()
    )

    SimpleCardView(
        card: EmailCard(
            id: "preview-ads-1",
            type: .ads,
            state: .unseen,
            priority: .medium,
            hpa: "Claim Deal",
            timeAgo: "1h ago",
            title: "Nike Air Max - Limited Time Sale",
            summary: "Get 28% off Nike Air Max sneakers. Premium comfort and style. Sale ends in 12 hours!",
            body: nil,
            htmlBody: nil,
            metaCTA: "Swipe Right: Claim Deal",
            intent: "e-commerce.promotional.sale",
            intentConfidence: 0.92,
            suggestedActions: [
                EmailAction(
                    actionId: "claim_deal",
                    displayName: "Claim Deal",
                    actionType: .goTo,
                    isPrimary: true,
                    priority: 1,
                    context: ["storeUrl": "https://nike.com/deals"]
                ),
                EmailAction(
                    actionId: "save_deal",
                    displayName: "Save for Later",
                    actionType: .inApp,
                    isPrimary: false,
                    priority: 2
                )
            ],
            store: "Nike",
            productImageUrl: "https://static.nike.com/a/images/t_PDP_1280_v1/f_auto,q_auto:eco/99486859-0ff3-46b4-949b-2d16af2ad421/custom-nike-dunk-high-by-you-shoes.png",
            brandName: "Nike",
            originalPrice: 180,
            salePrice: 129,
            discount: 28,
            urgent: true,
            expiresIn: "12 hours",
            isShoppingEmail: true
        ),
        isTopCard: true,
        viewModel: viewModel
    )
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black)
}

#Preview("MAIL Card - Calendar Invite") {
    let viewModel = EmailViewModel(
        userPreferences: UserPreferencesService(),
        appState: AppStateManager(),
        cardManagement: CardManagementService()
    )

    SimpleCardView(
        card: EmailCard(
            id: "preview-mail-2",
            type: .mail,
            state: .unseen,
            priority: .high,
            hpa: "Join Meeting",
            timeAgo: "15m ago",
            title: "Q4 Planning Meeting",
            summary: "Join us for quarterly planning discussion. October 30 at 2:00 PM via Zoom.",
            body: nil,
            htmlBody: nil,
            metaCTA: "Swipe Right: Join Meeting",
            intent: "calendar.meeting.invitation",
            intentConfidence: 0.98,
            suggestedActions: [
                EmailAction(
                    actionId: "join_meeting",
                    displayName: "Join Meeting",
                    actionType: .goTo,
                    isPrimary: true,
                    priority: 1,
                    context: ["platform": "Zoom", "meetingUrl": "https://zoom.us/j/123456789"]
                ),
                EmailAction(
                    actionId: "add_to_calendar",
                    displayName: "Add to Calendar",
                    actionType: .inApp,
                    isPrimary: false,
                    priority: 2
                )
            ],
            sender: SenderInfo(name: "John Smith", initial: "J", email: "john@company.com"),
            company: CompanyInfo(name: "Acme Corp", initials: "AC"),
            calendarInvite: CalendarInvite(
                platform: "Zoom",
                meetingUrl: "https://zoom.us/j/123456789",
                meetingTime: "Oct 30 at 2:00 PM",
                meetingTitle: "Q4 Planning Meeting",
                organizer: "John Smith",
                hasAcceptDecline: true
            )
        ),
        isTopCard: true,
        viewModel: viewModel
    )
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black)
}

#Preview("ADS Card - Newsletter") {
    let viewModel = EmailViewModel(
        userPreferences: UserPreferencesService(),
        appState: AppStateManager(),
        cardManagement: CardManagementService()
    )

    SimpleCardView(
        card: EmailCard(
            id: "preview-ads-2",
            type: .ads,
            state: .unseen,
            priority: .low,
            hpa: "Read Newsletter",
            timeAgo: "3h ago",
            title: "Weekly Tech Roundup - Issue #42",
            summary: "This week: AI breakthroughs, new frameworks, and industry insights. Plus exclusive discounts on courses!",
            body: nil,
            htmlBody: nil,
            metaCTA: "Swipe Right: Read Newsletter",
            intent: "newsletter.promotional.tech",
            intentConfidence: 0.88,
            suggestedActions: [
                EmailAction(
                    actionId: "view_details",
                    displayName: "Read Newsletter",
                    actionType: .goTo,
                    isPrimary: true,
                    priority: 1
                ),
                EmailAction(
                    actionId: "unsubscribe",
                    displayName: "Unsubscribe",
                    actionType: .goTo,
                    isPrimary: false,
                    priority: 2
                )
            ],
            sender: SenderInfo(name: "TechNews", initial: "T", email: "newsletter@technews.com"),
            isNewsletter: true,
            unsubscribeUrl: "https://technews.com/unsubscribe"
        ),
        isTopCard: true,
        viewModel: viewModel
    )
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black)
}

// MARK: - Holographic Shimmer Effect
struct HolographicShimmer: View {
    @State private var shimmerOffset: CGFloat = -300

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Multi-layered gradient for liquid glass effect
                LinearGradient(
                    colors: [
                        Color.cyan.opacity(0.2),
                        Color.purple.opacity(0.15),
                        Color.pink.opacity(0.2),
                        Color.blue.opacity(0.15)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Animated shimmer sweep
                LinearGradient(
                    colors: [
                        Color.white.opacity(0),
                        Color.white.opacity(0.4),
                        Color.cyan.opacity(0.6),
                        Color.purple.opacity(0.4),
                        Color.white.opacity(0.4),
                        Color.white.opacity(0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 100)
                .offset(x: shimmerOffset)
                .blur(radius: 20)

                // Iridescent spots
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.cyan.opacity(0.4),
                                Color.cyan.opacity(0)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 150, height: 150)
                    .offset(x: -50, y: -100)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.purple.opacity(0.3),
                                Color.purple.opacity(0)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 120
                        )
                    )
                    .frame(width: 180, height: 180)
                    .offset(x: 80, y: 120)
            }
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.card))
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 3.0)
                        .repeatForever(autoreverses: false)
                ) {
                    shimmerOffset = geometry.size.width + 300
                }
            }
        }
    }
}

// MARK: - Swipe Hint Overlay
/// Chevron-based hint that cycles through all 4 swipe directions
/// Shows on the very first card the user sees, then transforms into static CTA
struct SwipeHintOverlay: View {
    let actionLabel: String
    let onComplete: (() -> Void)? // Callback when animation cycle completes
    @State private var currentHint: HintDirection = .right
    @State private var hintOffset: CGSize = .zero
    @State private var animationCount: Int = 0
    @State private var showActionLabel: Bool = false
    private let maxAnimations = 4 // 1 cycle × 4 directions

    init(actionLabel: String, onComplete: (() -> Void)? = nil) {
        self.actionLabel = actionLabel
        self.onComplete = onComplete
    }

    enum HintDirection: CaseIterable {
        case right, left, down, up

        var chevron: String {
            switch self {
            case .right: return "chevron.right"
            case .left: return "chevron.left"
            case .down: return "chevron.down"
            case .up: return "chevron.up"
            }
        }

        var label: String {
            switch self {
            case .right: return "Take Action"
            case .left: return "Dismiss"
            case .down: return "Snooze"
            case .up: return "Change Action"
            }
        }

        /// Directional bump offset for hint UI (teaches direction to swipe)
        var hintBumpOffset: CGSize {
            switch self {
            case .right: return CGSize(width: 15, height: 0)
            case .left: return CGSize(width: -15, height: 0)
            case .down: return CGSize(width: 0, height: 10)
            case .up: return CGSize(width: 0, height: -10)
            }
        }

        /// Chevron pattern for display (repeated 4 times)
        var chevronPattern: String {
            switch self {
            case .right: return ">>>"
            case .left: return "<<<"
            case .down: return "vvv"
            case .up: return "^^^"
            }
        }
    }

    var body: some View {
        // Unified hint display without separate "Action" label
        HStack(spacing: 4) {
            Text(currentHint.chevronPattern)
                .font(.system(size: showActionLabel ? 16 : 14, weight: .bold))
                .foregroundColor(.white)

            Text(showActionLabel ? actionLabel : currentHint.label)
                .font(.system(size: showActionLabel ? 16 : 14, weight: .semibold))
                .foregroundColor(.white)
                .padding(.leading, 4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, showActionLabel ? 12 : 10)
        .background(
            ZStack {
                // Gradient background
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.gray.opacity(0.0),
                                Color.gray.opacity(0.1),
                                Color.gray.opacity(0.2)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .blendMode(.multiply)

                // Shimmer overlay
                SwipeShimmer()
            }
        )
        .offset(x: hintOffset.width, y: hintOffset.height)
        .onAppear {
            startAnimation()
        }
    }

    func startAnimation() {
        // PHASE 1: Bump in direction (0.5s)
        withAnimation(.easeOut(duration: 0.5)) {
            hintOffset = currentHint.hintBumpOffset
        }

        // PHASE 2: Hold at peak (0.7s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            // PHASE 3: Return to center (0.4s)
            withAnimation(.easeIn(duration: 0.4)) {
                hintOffset = .zero
            }
        }

        // PHASE 4: Hold at center (0.3s) - ENSURES centered before next animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.9) {
            animationCount += 1

            // After 1 complete cycle, trigger transition to static CTA
            guard animationCount < maxAnimations else {
                withAnimation(.easeIn(duration: 0.3)) {
                    showActionLabel = true
                }
                // Call onComplete callback to trigger transition to static CTA
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onComplete?()
                }
                return
            }

            // Ensure we're at center before moving to next hint
            hintOffset = .zero

            // Move to next hint
            let allCases = HintDirection.allCases
            if let currentIndex = allCases.firstIndex(of: currentHint) {
                let nextIndex = (currentIndex + 1) % allCases.count
                currentHint = allCases[nextIndex]
            }

            // Repeat
            startAnimation()
        }
    }
}

// MARK: - Swipe Shimmer Effect
/// Classic "slide to unlock" shimmer effect - sweeps from left to right across entire width
struct SwipeShimmer: View {
    @State private var startPoint = UnitPoint(x: -0.5, y: 0.5)
    @State private var endPoint = UnitPoint(x: 0, y: 0.5)

    var body: some View {
        LinearGradient(
            colors: [
                Color.white.opacity(0),
                Color.white.opacity(0.11),
                Color.white.opacity(0.22),
                Color.white.opacity(0.11),
                Color.white.opacity(0)
            ],
            startPoint: startPoint,
            endPoint: endPoint
        )
        .clipShape(Capsule())
        .onAppear {
            withAnimation(
                Animation.linear(duration: 1.875)
                    .repeatForever(autoreverses: false)
            ) {
                startPoint = UnitPoint(x: 1.0, y: 0.5)
                endPoint = UnitPoint(x: 1.5, y: 0.5)
            }
        }
    }
}

// MARK: - Rich Card Background Component

/// Rich card background with visually stunning effects
/// MAIL: Nebula/galaxy with animated particles and color shifting
/// ADS: Scenic nature backgrounds (forest, mountains, etc.)
struct RichCardBackground: View {
    let cardType: CardType
    let animationSpeed: Double

    @State private var animationPhase: CGFloat = 0
    @State private var particleOffsets: [CGSize] = []
    @State private var particleOpacities: [Double] = []

    init(for cardType: CardType, animationSpeed: Double = 30) {
        self.cardType = cardType
        self.animationSpeed = animationSpeed
    }

    var body: some View {
        ZStack {
            switch cardType {
            case .mail:
                // Nebula/Galaxy background with animated particles
                NebulaBackground(
                    animationPhase: animationPhase,
                    particleOffsets: $particleOffsets,
                    particleOpacities: $particleOpacities
                )

            case .ads:
                // Scenic nature background (forest/mountain aesthetic)
                ScenicBackground(animationPhase: animationPhase)
            }
        }
        .onAppear {
            // Initialize particles for nebula
            if cardType == .mail {
                particleOffsets = (0..<40).map { _ in
                    CGSize(
                        width: CGFloat.random(in: -150...150),
                        height: CGFloat.random(in: -200...200)
                    )
                }
                particleOpacities = (0..<40).map { _ in
                    Double.random(in: 0.1...0.5)
                }
            }

            // Start animation
            withAnimation(
                .easeInOut(duration: animationSpeed)
                .repeatForever(autoreverses: true)
            ) {
                animationPhase = 1.0
            }
        }
    }
}

// MARK: - Nebula Background (MAIL)

/// Deep space nebula effect with glowing particles and color shifts
struct NebulaBackground: View {
    let animationPhase: CGFloat
    @Binding var particleOffsets: [CGSize]
    @Binding var particleOpacities: [Double]

    var body: some View {
        ZStack {
            // Deep space base
            Color.black.opacity(0.9)

            // Nebula clouds - layered gradients with different colors
            RadialGradient(
                colors: [
                    Color(red: 0.2, green: 0.1, blue: 0.4, opacity: 0.6), // Deep purple
                    Color(red: 0.1, green: 0.15, blue: 0.3, opacity: 0.3), // Dark blue
                    Color.clear
                ],
                center: .init(x: 0.3, y: 0.4),
                startRadius: 0,
                endRadius: 300
            )
            .scaleEffect(1.0 + animationPhase * 0.1)
            .blur(radius: 60)

            RadialGradient(
                colors: [
                    Color(red: 0.4, green: 0.2, blue: 0.6, opacity: 0.5), // Bright purple
                    Color(red: 0.2, green: 0.3, blue: 0.7, opacity: 0.3), // Blue-purple
                    Color.clear
                ],
                center: .init(x: 0.7, y: 0.6),
                startRadius: 0,
                endRadius: 250
            )
            .scaleEffect(1.0 + animationPhase * 0.15)
            .blur(radius: 50)
            .offset(x: animationPhase * 20, y: animationPhase * -15)

            RadialGradient(
                colors: [
                    Color(red: 0.1, green: 0.4, blue: 0.7, opacity: 0.4), // Cyan-blue
                    Color.clear
                ],
                center: .init(x: 0.5, y: 0.2),
                startRadius: 0,
                endRadius: 200
            )
            .scaleEffect(1.0 + animationPhase * 0.12)
            .blur(radius: 40)
            .offset(x: animationPhase * -15, y: animationPhase * 20)

            // Stars/particles
            GeometryReader { geometry in
                ForEach(0..<particleOffsets.count, id: \.self) { i in
                    Circle()
                        .fill(Color.white.opacity(particleOpacities.indices.contains(i) ? particleOpacities[i] : 0.3))
                        .frame(width: CGFloat.random(in: 1...3), height: CGFloat.random(in: 1...3))
                        .offset(particleOffsets.indices.contains(i) ? particleOffsets[i] : .zero)
                        .blur(radius: 0.5)
                }
            }

            // Glowing nebula highlights
            RadialGradient(
                colors: [
                    Color(red: 0.6, green: 0.3, blue: 0.8, opacity: 0.3), // Bright magenta
                    Color.clear
                ],
                center: .init(x: 0.2, y: 0.7),
                startRadius: 0,
                endRadius: 150
            )
            .scaleEffect(1.0 + animationPhase * 0.2)
            .blur(radius: 30)
            .blendMode(.screen)
        }
    }
}

// MARK: - Scenic Background (ADS)

/// Light galaxy theme for shopping/promotional content
/// Uses white/blue/orange colors instead of mail's purple/pink for better legibility
struct ScenicBackground: View {
    let animationPhase: CGFloat

    var body: some View {
        ZStack {
            // Light base (white with subtle blue tint)
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.96, blue: 0.98), // Nearly white with blue tint
                    Color(red: 0.93, green: 0.95, blue: 0.99), // Very light sky blue
                    Color(red: 0.94, green: 0.94, blue: 0.97)  // Light neutral blue
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Blue nebula clouds
            RadialGradient(
                colors: [
                    Color(red: 0.4, green: 0.6, blue: 0.9, opacity: 0.3), // Bright blue
                    Color(red: 0.5, green: 0.7, blue: 0.95, opacity: 0.2), // Sky blue
                    Color.clear
                ],
                center: .init(x: 0.3, y: 0.4),
                startRadius: 0,
                endRadius: 300
            )
            .scaleEffect(1.0 + animationPhase * 0.1)
            .blur(radius: 60)

            // Orange accent nebula
            RadialGradient(
                colors: [
                    Color(red: 0.95, green: 0.6, blue: 0.3, opacity: 0.25), // Bright orange
                    Color(red: 0.98, green: 0.7, blue: 0.4, opacity: 0.15), // Light orange
                    Color.clear
                ],
                center: .init(x: 0.7, y: 0.6),
                startRadius: 0,
                endRadius: 250
            )
            .scaleEffect(1.0 + animationPhase * 0.15)
            .blur(radius: 50)
            .offset(x: animationPhase * 20, y: animationPhase * -15)

            // Cyan-blue highlight
            RadialGradient(
                colors: [
                    Color(red: 0.3, green: 0.7, blue: 0.95, opacity: 0.2), // Bright cyan-blue
                    Color.clear
                ],
                center: .init(x: 0.5, y: 0.2),
                startRadius: 0,
                endRadius: 200
            )
            .scaleEffect(1.0 + animationPhase * 0.12)
            .blur(radius: 40)
            .offset(x: animationPhase * -15, y: animationPhase * 20)

            // White glow highlight (shopping accent)
            RadialGradient(
                colors: [
                    Color.white.opacity(0.4),
                    Color(red: 0.9, green: 0.95, blue: 1.0, opacity: 0.2),
                    Color.clear
                ],
                center: .init(x: 0.2, y: 0.7),
                startRadius: 0,
                endRadius: 150
            )
            .scaleEffect(1.0 + animationPhase * 0.2)
            .blur(radius: 30)
            .blendMode(.screen)
        }
    }
}
