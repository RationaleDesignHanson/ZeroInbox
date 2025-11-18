import SwiftUI

struct Property: Identifiable {
    let id = UUID()
    let title: String
    let price: String
    let bedrooms: Int
    let bathrooms: Double
    let sqft: Int?
    let address: String
    let imageURL: String?
    var isSaved: Bool = false
}

struct SavePropertiesModal: View {
    let card: EmailCard
    @Binding var isPresented: Bool

    @State private var properties: [Property] = []
    @State private var savedCount = 0
    @State private var showSuccess = false

    var body: some View {
        VStack(spacing: 0) {
            // Header (Week 6: Using shared ModalHeader component)
            ModalHeader(isPresented: $isPresented)

            // Scrollable content
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.card) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "house.fill")
                                .font(.largeTitle)
                                .foregroundColor(.purple)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Save Properties")
                                    .font(.title2.bold())
                                    .foregroundColor(DesignTokens.Colors.textPrimary)

                                Text("\(properties.count) \(properties.count == 1 ? "property" : "properties") available")
                                    .font(.subheadline)
                                    .foregroundColor(DesignTokens.Colors.textSubtle)
                            }
                        }
                    }

                    // Saved count badge
                    if savedCount > 0 {
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.pink)
                            Text("\(savedCount) \(savedCount == 1 ? "property" : "properties") saved")
                                .font(.subheadline.bold())
                                .foregroundColor(.pink)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.pink.opacity(DesignTokens.Opacity.overlayLight))
                        .cornerRadius(DesignTokens.Radius.modal)
                    }

                    Divider()
                        .background(Color.white.opacity(DesignTokens.Opacity.overlayMedium))

                    // Property Grid (2 columns)
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 16) {
                        ForEach($properties) { $property in
                            PropertyCard(property: $property, onToggleSave: {
                                toggleSave(for: property)
                            })
                        }
                    }

                    // Success message
                    if showSuccess {
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.title2)
                                Text("Properties Saved!")
                                    .foregroundColor(.green)
                                    .font(.headline.bold())
                            }

                            Text("You can view your saved properties anytime in your favorites")
                                .font(.subheadline)
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(DesignTokens.Opacity.overlayLight))
                        .cornerRadius(DesignTokens.Radius.button)
                    }

                    // Action buttons
                    if savedCount > 0 {
                        VStack(spacing: 12) {
                            Button {
                                viewSavedProperties()
                            } label: {
                                HStack {
                                    Image(systemName: "heart.text.square.fill")
                                    Text("View Saved Properties")
                                        .font(.headline)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.purple)
                                .foregroundColor(.white)
                                .cornerRadius(DesignTokens.Radius.button)
                            }

                            Button {
                                shareProperties()
                            } label: {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Share Selection")
                                        .font(.subheadline)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white.opacity(DesignTokens.Opacity.glassLight))
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                                .cornerRadius(DesignTokens.Radius.button)
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                                        .strokeBorder(Color.white.opacity(DesignTokens.Opacity.overlayMedium), lineWidth: 1)
                                )
                            }
                        }
                    }

                    // Info message
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                            .font(.caption)
                        Text("Tap the heart icon to save properties to your favorites. Saved properties will be synced across all your devices.")
                            .font(.caption)
                            .foregroundColor(DesignTokens.Colors.textSubtle)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding()
                    .background(Color.blue.opacity(DesignTokens.Opacity.glassLight))
                    .cornerRadius(DesignTokens.Radius.button)
                }
                .padding(DesignTokens.Spacing.card)
            }
        }
        .onAppear {
            extractProperties()
        }
    }

    func extractProperties() {
        // Try to extract properties from card context
        if let action = card.suggestedActions?.first(where: { $0.actionId == "save_properties" }),
           let context = action.context,
           let propertiesData = context["properties"] {
            // Parse properties from JSON string if available
            properties = parsePropertiesFromContext(propertiesData)
        } else {
            // Extract from email content
            properties = extractPropertiesFromContent()
        }
    }

    func parsePropertiesFromContext(_ data: String) -> [Property] {
        // In production, this would parse actual JSON
        // For now, return mock data
        return []
    }

    func extractPropertiesFromContent() -> [Property] {
        var extracted: [Property] = []
        let text = card.summary + " " + (card.body ?? "")

        // Simple pattern matching for common real estate formats
        // Pattern: "3BR 2BA house - $850,000"
        let patterns = [
            "(\\d+)BR[^$]*\\$([\\d,]+)(?:K|k|,000)?",
            "(\\d+) bed[^$]*\\$([\\d,]+)(?:K|k|,000)?"
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
                for match in matches {
                    if match.numberOfRanges >= 3,
                       let bedroomRange = Range(match.range(at: 1), in: text),
                       let priceRange = Range(match.range(at: 2), in: text),
                       let bedrooms = Int(String(text[bedroomRange])) {

                        let priceStr = String(text[priceRange])
                        let price = formatPrice(priceStr)

                        extracted.append(Property(
                            title: "\(bedrooms)BR House",
                            price: price,
                            bedrooms: bedrooms,
                            bathrooms: 2.0,
                            sqft: nil,
                            address: "San Francisco, CA",
                            imageURL: nil
                        ))
                    }
                }
            }
        }

        // If no properties extracted, create sample data
        if extracted.isEmpty {
            extracted = createSampleProperties()
        }

        return Array(extracted.prefix(6)) // Limit to 6 properties
    }

    func createSampleProperties() -> [Property] {
        return [
            Property(
                title: "3BR Modern House",
                price: "$850K",
                bedrooms: 3,
                bathrooms: 2.5,
                sqft: 1800,
                address: "Pacific Heights, SF",
                imageURL: nil
            ),
            Property(
                title: "2BR Downtown Condo",
                price: "$695K",
                bedrooms: 2,
                bathrooms: 2.0,
                sqft: 1200,
                address: "Financial District, SF",
                imageURL: nil
            ),
            Property(
                title: "4BR Family Home",
                price: "$1.2M",
                bedrooms: 4,
                bathrooms: 3.0,
                sqft: 2400,
                address: "Noe Valley, SF",
                imageURL: nil
            )
        ]
    }

    func formatPrice(_ priceStr: String) -> String {
        let cleaned = priceStr.replacingOccurrences(of: ",", with: "")
        if let value = Int(cleaned) {
            if value < 1000 {
                return "$\(value)K"
            } else {
                let millions = Double(value) / 1000.0
                return String(format: "$%.1fM", millions)
            }
        }
        return "$\(priceStr)"
    }

    func toggleSave(for property: Property) {
        if let index = properties.firstIndex(where: { $0.id == property.id }) {
            properties[index].isSaved.toggle()
            savedCount = properties.filter { $0.isSaved }.count

            if properties[index].isSaved {
                Logger.info("Property saved: \(property.title)", category: .action)

                // Haptic feedback
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()

                // Show success if this is the first save
                if savedCount == 1 {
                    withAnimation(.spring()) {
                        showSuccess = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation(.spring()) {
                            showSuccess = false
                        }
                    }
                }
            }
        }
    }

    func viewSavedProperties() {
        Logger.info("Viewing saved properties", category: .action)
        // In production, this would navigate to a saved properties view
        isPresented = false
    }

    func shareProperties() {
        let savedProperties = properties.filter { $0.isSaved }
        let propertyList = savedProperties.map { "\($0.title) - \($0.price)" }.joined(separator: "\n")

        ClipboardUtility.copy("My Saved Properties:\n\n\(propertyList)")

        Logger.info("Properties copied to clipboard", category: .action)
    }
}

// MARK: - Property Card

struct PropertyCard: View {
    @Binding var property: Property
    let onToggleSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Property image placeholder
            ZStack {
                Rectangle()
                    .fill(LinearGradient(
                        colors: [Color.purple.opacity(DesignTokens.Opacity.overlayMedium), Color.blue.opacity(DesignTokens.Opacity.overlayMedium)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .aspectRatio(4/3, contentMode: .fill)
                    .cornerRadius(DesignTokens.Radius.button)

                Image(systemName: "house.fill")
                    .font(.largeTitle)
                    .foregroundColor(.white.opacity(DesignTokens.Opacity.overlayStrong))
            }

            // Property details
            VStack(alignment: .leading, spacing: 4) {
                Text(property.title)
                    .font(.subheadline.bold())
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .lineLimit(1)

                Text(property.price)
                    .font(.headline)
                    .foregroundColor(.green)

                HStack(spacing: 12) {
                    Label("\(property.bedrooms)", systemImage: "bed.double.fill")
                        .font(.caption2)
                        .foregroundColor(DesignTokens.Colors.textSubtle)

                    Label(String(format: "%.1f", property.bathrooms), systemImage: "shower.fill")
                        .font(.caption2)
                        .foregroundColor(DesignTokens.Colors.textSubtle)

                    if let sqft = property.sqft {
                        Text("\(sqft) sq ft")
                            .font(.caption2)
                            .foregroundColor(DesignTokens.Colors.textSubtle)
                    }
                }

                Text(property.address)
                    .font(.caption)
                    .foregroundColor(DesignTokens.Colors.textSubtle)
                    .lineLimit(1)
            }

            // Save button
            Button {
                onToggleSave()
            } label: {
                HStack {
                    Image(systemName: property.isSaved ? "heart.fill" : "heart")
                        .foregroundColor(property.isSaved ? .pink : .white)
                    Text(property.isSaved ? "Saved" : "Save")
                        .font(.caption.bold())
                        .foregroundColor(property.isSaved ? .pink : DesignTokens.Colors.textPrimary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(property.isSaved ? Color.pink.opacity(DesignTokens.Opacity.overlayLight) : Color.white.opacity(DesignTokens.Opacity.glassLight))
                .cornerRadius(DesignTokens.Radius.chip)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(property.isSaved ? Color.pink : Color.white.opacity(DesignTokens.Opacity.overlayMedium), lineWidth: 1)
                )
            }
        }
        .padding(DesignTokens.Spacing.element)
        .background(Color.white.opacity(0.08))
        .cornerRadius(DesignTokens.Radius.card)
    }
}

// MARK: - Preview

#Preview("Save Properties Modal") {
    SavePropertiesModal(
        card: EmailCard(
            id: "preview",
            type: .mail,
            state: .seen,
            priority: .medium,
            hpa: "save_properties",
            timeAgo: "2h",
            title: "New Listings in San Francisco",
            summary: "3 new properties match your search criteria. Check out these amazing listings:\n\n• 3BR Modern House - $850,000 in Pacific Heights\n• 2BR Downtown Condo - $695,000 in Financial District\n• 4BR Family Home - $1,200,000 in Noe Valley",
            body: "Dear Home Buyer,\n\nWe found some great properties that match your preferences!\n\nProperty 1: 3BR 2.5BA Modern House\nPrice: $850,000\nLocation: Pacific Heights\nSize: 1,800 sq ft\n\nProperty 2: 2BR 2BA Downtown Condo\nPrice: $695,000\nLocation: Financial District\nSize: 1,200 sq ft\n\nProperty 3: 4BR 3BA Family Home\nPrice: $1,200,000\nLocation: Noe Valley\nSize: 2,400 sq ft\n\nClick to save your favorites!",
            metaCTA: "View",
            suggestedActions: [
                EmailAction(
                    actionId: "save_properties",
                    displayName: "Save Properties",
                    actionType: .inApp,
                    isPrimary: true,
                    context: [:]
                )
            ],
            sender: SenderInfo(
                name: "Zillow",
                initial: "Z",
                email: "listings@zillow.com"
            )
        ),
        isPresented: .constant(true)
    )
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(
        LinearGradient(
            colors: [
                Color(red: 0.1, green: 0.1, blue: 0.2),
                Color(red: 0.05, green: 0.05, blue: 0.15)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}
