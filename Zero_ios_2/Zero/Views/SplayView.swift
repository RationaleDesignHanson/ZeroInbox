import SwiftUI

struct SplayGroup {
    let id: String
    let name: String
    let subtitle: String
    let icon: String
    let filter: (EmailCard) -> Bool
}

struct SplayView: View {
    @Binding var isPresented: Bool
    let cards: [EmailCard]
    let archetype: CardType
    let onSelectCard: (EmailCard) -> Void
    @EnvironmentObject var viewModel: EmailViewModel

    var unseenCards: [EmailCard] {
        cards.filter { $0.type == archetype && $0.state == .unseen }
    }

    var savedDealsCards: [EmailCard] {
        cards.filter { card in
            card.type == .ads && viewModel.isSaved(cardId: card.id)
        }
    }
    
    var groups: [SplayGroup] {
        let modern = archetype
        switch modern {
        case .mail:
            // Semantic categories for better organization
            return [
                SplayGroup(
                    id: "high_priority",
                    name: "High Priority",
                    subtitle: "Urgent & Important",
                    icon: "exclamationmark.triangle.fill",
                    filter: { $0.priority == .critical || $0.priority == .high }
                ),
                SplayGroup(
                    id: "work",
                    name: "Work & Projects",
                    subtitle: "Professional & Business",
                    icon: "briefcase.fill",
                    filter: { email in
                        // Work-related intents
                        let workKeywords = ["work", "project", "meeting", "proposal", "client", "business", "office", "deadline", "task", "team"]
                        let intent = email.intent?.lowercased() ?? ""
                        let body = (email.body ?? email.summary).lowercased()
                        return workKeywords.contains(where: { intent.contains($0) || body.contains($0) }) ||
                               email.intent?.contains("work.") == true ||
                               email.intent?.contains("project.") == true
                    }
                ),
                SplayGroup(
                    id: "personal",
                    name: "Personal & Family",
                    subtitle: "Family & Friends",
                    icon: "person.2.fill",
                    filter: { email in
                        // Personal/family emails including kids
                        if email.kid != nil || email.isSchoolEmail == true {
                            return true
                        }
                        let personalKeywords = ["family", "friend", "personal", "home", "child", "kid", "school", "parent", "teacher"]
                        let intent = email.intent?.lowercased() ?? ""
                        let body = (email.body ?? email.summary).lowercased()
                        return personalKeywords.contains(where: { intent.contains($0) || body.contains($0) }) ||
                               email.intent?.contains("family.") == true ||
                               email.intent?.contains("personal.") == true
                    }
                ),
                SplayGroup(
                    id: "finance",
                    name: "Finance & Documents",
                    subtitle: "Bills, Statements & Tax",
                    icon: "dollarsign.circle.fill",
                    filter: { email in
                        // Financial and important documents
                        let financeKeywords = ["invoice", "bill", "statement", "payment", "tax", "w2", "w-2", "1099", "receipt", "financial", "bank", "credit", "debit", "balance"]
                        let intent = email.intent?.lowercased() ?? ""
                        let title = email.title.lowercased()
                        let body = (email.body ?? email.summary).lowercased()
                        return financeKeywords.contains(where: { intent.contains($0) || title.contains($0) || body.contains($0) }) ||
                               email.intent?.contains("finance.") == true ||
                               email.intent?.contains("payment.") == true ||
                               email.paymentAmount != nil
                    }
                )
            ]

        case .ads:
            // Intent-based categories for better organization
            return [
                SplayGroup(
                    id: "saved",
                    name: "Saved Items",
                    subtitle: "Your Bookmarked Deals",
                    icon: "bookmark.fill",
                    filter: { viewModel.isSaved(cardId: $0.id) }
                ),
                SplayGroup(
                    id: "shopping",
                    name: "Shopping & Deals",
                    subtitle: "Products & Sales",
                    icon: "cart.fill",
                    filter: { email in
                        // Shopping, products, sales, deals
                        if email.isShoppingEmail == true || email.store != nil {
                            return true
                        }
                        let shoppingKeywords = ["sale", "deal", "discount", "product", "shop", "buy", "order", "purchase", "cart", "checkout", "price"]
                        let intent = email.intent?.lowercased() ?? ""
                        let title = email.title.lowercased()
                        return shoppingKeywords.contains(where: { intent.contains($0) || title.contains($0) }) ||
                               email.intent?.contains("e-commerce.") == true ||
                               email.intent?.contains("shopping.") == true ||
                               email.salePrice != nil ||
                               email.discount != nil
                    }
                ),
                SplayGroup(
                    id: "travel",
                    name: "Travel & Dining",
                    subtitle: "Restaurants, Hotels & Flights",
                    icon: "airplane.circle.fill",
                    filter: { email in
                        // Travel, dining, restaurants, hotels
                        let travelKeywords = ["flight", "hotel", "restaurant", "reservation", "booking", "travel", "trip", "vacation", "airline", "airport", "dining", "food", "delivery"]
                        let intent = email.intent?.lowercased() ?? ""
                        let title = email.title.lowercased()
                        let body = (email.body ?? email.summary).lowercased()
                        return travelKeywords.contains(where: { intent.contains($0) || title.contains($0) || body.contains($0) }) ||
                               email.intent?.contains("travel.") == true ||
                               email.intent?.contains("dining.") == true ||
                               email.intent?.contains("food.") == true ||
                               email.airline != nil
                    }
                ),
                SplayGroup(
                    id: "subscriptions",
                    name: "Subscriptions",
                    subtitle: "Recurring Services",
                    icon: "arrow.clockwise.circle.fill",
                    filter: { email in
                        // Subscription services
                        if email.isSubscription == true {
                            return true
                        }
                        let subscriptionKeywords = ["subscription", "recurring", "membership", "renew", "cancel", "billing", "monthly", "annual", "plan", "service"]
                        let intent = email.intent?.lowercased() ?? ""
                        let title = email.title.lowercased()
                        let body = (email.body ?? email.summary).lowercased()
                        return subscriptionKeywords.contains(where: { intent.contains($0) || title.contains($0) || body.contains($0) }) ||
                               email.intent?.contains("subscription.") == true ||
                               email.subscriptionAmount != nil ||
                               email.cancellationUrl != nil
                    }
                ),
                SplayGroup(
                    id: "newsletters",
                    name: "Newsletters",
                    subtitle: "Content & Updates",
                    icon: "newspaper.fill",
                    filter: { email in
                        // Newsletters and content updates
                        if email.isNewsletter == true {
                            return true
                        }
                        let newsletterKeywords = ["newsletter", "update", "digest", "weekly", "monthly", "roundup", "news", "article", "blog"]
                        let intent = email.intent?.lowercased() ?? ""
                        let title = email.title.lowercased()
                        return newsletterKeywords.contains(where: { intent.contains($0) || title.contains($0) }) ||
                               email.intent?.contains("newsletter.") == true ||
                               email.keyLinks != nil ||
                               email.keyTopics != nil
                    }
                )
            ]
        }
    }
    
    var groupedCards: [(SplayGroup, Int)] {
        groups.map { group in
            let count = unseenCards.filter(group.filter).count
            return (group, count)
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            AnimatedGradientBackground(
                for: archetype,
                animationSpeed: 30
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button {
                        isPresented = false
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    VStack {
                        Text(archetype.displayName)
                            .font(.title2.bold())
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(DesignTokens.Opacity.overlayMedium), radius: 2, y: 1)
                        Text("Organize by Category")
                            .font(.caption)
                            .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color.black.opacity(DesignTokens.Opacity.overlayMedium))
                
                // Grid of groups
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: DesignTokens.Spacing.section),
                        GridItem(.flexible(), spacing: DesignTokens.Spacing.section)
                    ], spacing: DesignTokens.Spacing.section) {
                        ForEach(groupedCards, id: \.0.id) { group, count in
                            SplayGroupCard(
                                group: group,
                                count: count,
                                archetype: archetype
                            )
                            .onTapGesture {
                                if count > 0 {
                                    // Find first card in this group
                                    if let firstCard = unseenCards.first(where: group.filter) {
                                        onSelectCard(firstCard)
                                        isPresented = false
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    var groupLabel: String {
        let modern = archetype
        switch modern {
        case .mail: return "Email Overview"
        case .ads: return "Shopping Overview"
        }
    }

    var groupType: String {
        let modern = archetype
        switch modern {
        case .mail: return "items"
        case .ads: return "stores"
        }
    }
}

struct SplayGroupCard: View {
    let group: SplayGroup
    let count: Int
    let archetype: CardType
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.section) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.container)
                    .fill(gradientColor)
                    .frame(width: 64, height: 64)
                    .shadow(color: .black.opacity(DesignTokens.Opacity.overlayMedium), radius: 10, y: 5)
                
                Image(systemName: group.icon)
                    .font(.system(size: 28))
                    .foregroundColor(.white)
            }
            
            // Name
            Text(group.name)
                .font(.headline.bold())
                .foregroundColor(DesignTokens.Colors.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            // Subtitle
            Text(group.subtitle)
                .font(.caption)
                .foregroundColor(DesignTokens.Colors.textSubtle)
                .multilineTextAlignment(.center)
                .lineLimit(1)
            
            // Email count badge
            HStack(spacing: 6) {
                Text("\(count)")
                    .font(.subheadline.bold())
                Text(count == 1 ? "email" : "emails")
                    .font(.caption)
            }
            .foregroundColor(count > 0 ? .white : .white.opacity(0.4))
            .padding(.horizontal, DesignTokens.Spacing.component)
            .padding(.vertical, 6)
            .background(count > 0 ? Color.white.opacity(DesignTokens.Opacity.overlayLight) : Color.white.opacity(DesignTokens.Opacity.glassLight))
            .cornerRadius(DesignTokens.Radius.button)
            
            // Arrow indicator
            if count > 0 {
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.4))
                    .font(.caption)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.container)
                .fill(Color.white.opacity(count > 0 ? 0.1 : 0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.container)
                        .strokeBorder(Color.white.opacity(count > 0 ? 0.2 : 0.1), lineWidth: 2)
                )
        )
        .opacity(count > 0 ? 1.0 : 0.5)
    }
    
    var gradientColor: LinearGradient {
        let colors = gradientColors(for: group.id)
        return LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    func gradientColors(for groupId: String) -> [Color] {
        switch groupId {
        case "saved": return [Color.orange, Color.pink]
        case "emma": return [Color(red: 0.96, green: 0.47, blue: 0.60), Color(red: 0.98, green: 0.31, blue: 0.49)]
        case "lucas": return [Color(red: 0.45, green: 0.62, blue: 0.95), Color(red: 0.36, green: 0.44, blue: 0.92)]
        case "zoe": return [Color(red: 0.72, green: 0.45, blue: 0.95), Color(red: 0.96, green: 0.47, blue: 0.80)]
        case "general": return [Color(red: 1.0, green: 0.76, blue: 0.29), Color(red: 1.0, green: 0.60, blue: 0.20)]
        case "hot": return [Color.red, Color.orange]
        case "warm": return [Color.orange, Color.yellow]
        case "cold": return [Color.blue, Color.cyan]
        case "critical": return [Color.red, Color.pink]
        case "high": return [Color.orange, Color.yellow]
        default: return [archetypeColor, archetypeColor.opacity(DesignTokens.Opacity.textSubtle)]
        }
    }
    
    var archetypeColor: Color {
        let modern = archetype
        switch modern {
        case .mail: return Color(red: 0.388, green: 0.6, blue: 0.945)      // Blue/Teal
        case .ads: return Color(red: 0.063, green: 0.725, blue: 0.506)        // Green/Emerald
        }
    }
}

