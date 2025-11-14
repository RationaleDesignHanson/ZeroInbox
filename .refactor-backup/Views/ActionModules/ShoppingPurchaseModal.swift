import SwiftUI

struct ShoppingPurchaseModal: View {
    let card: EmailCard
    @Binding var isPresented: Bool
    var selectedAction: String? = nil // "save_deal" or nil for purchase
    @EnvironmentObject var viewModel: EmailViewModel

    @State private var quantity = 1
    @State private var showPurchaseSuccess = false
    @State private var showSaveSuccess = false
    @State private var isAddingToCart = false
    @State private var errorMessage: String?
    @State private var offerUrl: String?
    @State private var promoCode: String?
    @State private var recommendedBooks: [(title: String, author: String, price: Double, image: String)] = []

    // Determine if this is a "view offer" email (needs website) or "add to cart" email
    var shouldShowWebButton: Bool {
        // Show web button if:
        // 1. No price data (incomplete product info)
        // 2. OR has promo code
        // 3. OR email body contains URLs
        return (card.salePrice == nil && offerUrl != nil) ||
               promoCode != nil ||
               (offerUrl != nil && selectedAction == "view_offer")
    }

    var body: some View {
        VStack(spacing: 0) {
            // Custom header
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
            .padding(.top, 20)  // Ensure header clears sheet top rounded corner
            .padding(.horizontal)
            .padding(.bottom, DesignTokens.Spacing.inline)

            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.card) {
                    // Product image
                    if let imageUrl = card.productImageUrl {
                        AsyncImage(url: URL(string: imageUrl)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 250)
                                .clipped()
                                .cornerRadius(DesignTokens.Radius.container)
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 250)
                                .cornerRadius(DesignTokens.Radius.container)
                        }
                    }
                    
                    // Product info
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.component) {
                        if let brand = card.brandName {
                            Text(brand)
                                .font(.subheadline.bold())
                                .foregroundColor(DesignTokens.Colors.textSubtle)
                                .textCase(.uppercase)
                        }
                        
                        Text(card.title)
                            .font(.title2.bold())
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                        
                        // Pricing
                        if let salePrice = card.salePrice, let originalPrice = card.originalPrice {
                            HStack(spacing: DesignTokens.Spacing.component) {
                                Text("$\(String(format: "%.2f", salePrice))")
                                    .font(.title.bold())
                                    .foregroundColor(DesignTokens.Colors.textPrimary)

                                Text("$\(String(format: "%.2f", originalPrice))")
                                    .font(.title3)
                                    .foregroundColor(DesignTokens.Colors.textSubtle)
                                    .strikethrough()
                                
                                if let discount = card.discount {
                                    Text("\(discount)% OFF")
                                        .font(.caption.bold())
                                        .foregroundColor(DesignTokens.Colors.textPrimary)
                                        .padding(.horizontal, DesignTokens.Spacing.inline)
                                        .padding(.vertical, 4)
                                        .background(Color.green)
                                        .cornerRadius(DesignTokens.Radius.chip)
                                }
                            }
                        }
                        
                        // Urgency
                        if card.urgent == true, let expiresIn = card.expiresIn {
                            HStack(spacing: 6) {
                                Image(systemName: "clock.fill")
                                    .foregroundColor(.red)
                                Text("Expires in \(expiresIn)")
                                    .font(.subheadline.bold())
                                    .foregroundColor(DesignTokens.Colors.textPrimary)
                            }
                            .padding(.horizontal, DesignTokens.Spacing.component)
                            .padding(.vertical, DesignTokens.Spacing.inline)
                            .background(Color.red.opacity(0.3))
                            .cornerRadius(DesignTokens.Radius.chip)
                        }
                    }

                    Divider()
                        .background(Color.white.opacity(0.3))

                    // Recommended Books Section (if browse_books action)
                    if selectedAction == "browse_books" && !recommendedBooks.isEmpty {
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.component) {
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text("Recommended for \(card.kid?.name ?? "Your Child")")
                                    .font(.headline)
                                    .foregroundColor(DesignTokens.Colors.textPrimary)
                            }

                            Text("Age-appropriate books for \(card.kid?.grade ?? "this grade level")")
                                .font(.caption)
                                .foregroundColor(DesignTokens.Colors.textSubtle)

                            ForEach(Array(recommendedBooks.enumerated()), id: \.offset) { index, book in
                                Button {
                                    // Could add book to cart or save
                                    Logger.info("📚 Selected book: \(book.title)", category: .action)
                                } label: {
                                    HStack(spacing: DesignTokens.Spacing.component) {
                                        Image(systemName: book.image)
                                            .font(.title2)
                                            .foregroundColor(.blue)
                                            .frame(width: 40)

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(book.title)
                                                .font(.subheadline.bold())
                                                .foregroundColor(DesignTokens.Colors.textPrimary)
                                            Text(book.author)
                                                .font(.caption)
                                                .foregroundColor(DesignTokens.Colors.textSubtle)
                                        }

                                        Spacer()

                                        Text("$\(String(format: "%.2f", book.price))")
                                            .font(.subheadline.bold())
                                            .foregroundColor(.green)
                                    }
                                    .padding()
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(DesignTokens.Radius.button)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(DesignTokens.Radius.container)
                    }

                    // Description
                    StructuredSummaryView(card: card)
                    
                    // Store info
                    if let store = card.store {
                        HStack(spacing: DesignTokens.Spacing.component) {
                            Image(systemName: "bag.fill")
                                .foregroundColor(DesignTokens.Colors.textSubtle)
                            Text("Sold by \(store)")
                                .font(.subheadline)
                                .foregroundColor(DesignTokens.Colors.textSubtle)
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(DesignTokens.Radius.button)
                    }

                    // Quantity selector
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.component) {
                        Text("Quantity")
                            .font(.headline)
                            .foregroundColor(DesignTokens.Colors.textPrimary)

                        HStack(spacing: DesignTokens.Spacing.section) {
                            Button {
                                if quantity > 1 {
                                    quantity -= 1
                                }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(DesignTokens.Colors.textPrimary)
                            }

                            Text("\(quantity)")
                                .font(.title3.bold())
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                                .frame(minWidth: 40)

                            Button {
                                quantity += 1
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(DesignTokens.Colors.textPrimary)
                            }
                        }
                    }

                    // Promo Code Display (if detected)
                    if let promoCode = promoCode {
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.inline) {
                            Text("Promo Code")
                                .font(.subheadline.bold())
                                .foregroundColor(DesignTokens.Colors.textSubtle)

                            HStack {
                                Text(promoCode)
                                    .font(.title3.bold())
                                    .foregroundColor(DesignTokens.Colors.textPrimary)
                                    .padding(.horizontal, DesignTokens.Spacing.section)
                                    .padding(.vertical, DesignTokens.Spacing.component)
                                    .background(Color.white.opacity(0.2))
                                    .cornerRadius(DesignTokens.Radius.chip)

                                Button {
                                    UIPasteboard.general.string = promoCode
                                    let impact = UINotificationFeedbackGenerator()
                                    impact.notificationOccurred(.success)
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "doc.on.doc")
                                        Text("Copy")
                                    }
                                    .font(.subheadline.bold())
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, DesignTokens.Spacing.section)
                                    .padding(.vertical, DesignTokens.Spacing.component)
                                    .background(Color.white)
                                    .cornerRadius(DesignTokens.Radius.chip)
                                }
                            }
                        }
                    }

                    // Action buttons
                    VStack(spacing: DesignTokens.Spacing.component) {
                        if selectedAction == "save_deal" {
                            // Save Deal button
                            Button {
                                saveDeal()
                            } label: {
                                HStack {
                                    Image(systemName: viewModel.isSaved(cardId: card.id) ? "bookmark.fill" : "bookmark")
                                    Text(viewModel.isSaved(cardId: card.id) ? "Saved!" : "Save Deal")
                                        .font(.headline)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(viewModel.isSaved(cardId: card.id) ? Color.orange : Color.blue)
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                                .cornerRadius(DesignTokens.Radius.button)
                            }
                            .disabled(viewModel.isSaved(cardId: card.id))

                            if showSaveSuccess {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Deal saved! View in Splay View")
                                        .foregroundColor(.green)
                                }
                                .font(.subheadline.bold())
                            }
                        } else if shouldShowWebButton {
                            // View Offer on Website button
                            Button {
                                openOfferWebsite()
                            } label: {
                                HStack {
                                    Image(systemName: "safari")
                                    Text(promoCode != nil ? "View Offer & Apply Code" : "View Offer")
                                        .font(.headline)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                                .cornerRadius(DesignTokens.Radius.button)
                            }

                            if promoCode != nil {
                                Text("Code will be copied to clipboard")
                                    .font(.caption)
                                    .foregroundColor(DesignTokens.Colors.textSubtle)
                            }
                        } else {
                            // Add to Cart button (only if we have price data)
                            Button {
                                Task {
                                    await purchaseItem()
                                }
                            } label: {
                                HStack {
                                    if isAddingToCart {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "cart.fill")
                                    }
                                    if let salePrice = card.salePrice {
                                        Text(isAddingToCart ? "Adding..." : "Add to Cart - $\(String(format: "%.2f", salePrice * Double(quantity)))")
                                            .font(.headline)
                                    } else {
                                        Text(isAddingToCart ? "Adding..." : "Add to Cart")
                                            .font(.headline)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(isAddingToCart ? Color.green.opacity(0.7) : Color.green)
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                                .cornerRadius(DesignTokens.Radius.button)
                            }
                            .disabled(isAddingToCart)

                            if showPurchaseSuccess {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Added to Cart!")
                                        .foregroundColor(.green)
                                }
                                .font(.subheadline.bold())
                            }

                            if let errorMessage = errorMessage {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.red)
                                    Text(errorMessage)
                                        .foregroundColor(.red)
                                        .font(.caption)
                                }
                                .padding(.horizontal, DesignTokens.Spacing.component)
                                .padding(.vertical, DesignTokens.Spacing.inline)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(DesignTokens.Radius.chip)
                            }
                        }
                    }
                    .padding(.top, 20)
                }
                .padding(DesignTokens.Spacing.card)
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.2),
                    Color(red: 0.05, green: 0.05, blue: 0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .onAppear {
            extractOfferDetails()
            if selectedAction == "browse_books" {
                loadRecommendedBooks()
            }
        }
    }

    // MARK: - Helper Functions

    func loadRecommendedBooks() {
        // Generate age-appropriate book recommendations based on kid's grade
        guard let grade = card.kid?.grade else { return }

        // Parse grade level (e.g., "3rd Grade" -> 3)
        let gradeNumber = Int(grade.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) ?? 3

        // Grade-appropriate book recommendations
        if gradeNumber <= 2 {
            // K-2nd grade: Early readers
            recommendedBooks = [
                ("The Magic Tree House Series", "Mary Pope Osborne", 4.99, "book.fill"),
                ("Junie B. Jones", "Barbara Park", 5.99, "book.fill"),
                ("Frog and Toad Are Friends", "Arnold Lobel", 6.99, "book.fill"),
                ("Dog Man Series", "Dav Pilkey", 7.99, "book.fill")
            ]
        } else if gradeNumber <= 5 {
            // 3rd-5th grade: Middle grade
            recommendedBooks = [
                ("Wonder", "R.J. Palacio", 8.99, "book.fill"),
                ("Percy Jackson Series", "Rick Riordan", 9.99, "book.fill"),
                ("Diary of a Wimpy Kid", "Jeff Kinney", 7.99, "book.fill"),
                ("Harry Potter Series", "J.K. Rowling", 12.99, "book.fill"),
                ("The Wild Robot", "Peter Brown", 8.49, "book.fill")
            ]
        } else {
            // 6th+ grade: Young adult
            recommendedBooks = [
                ("The Hunger Games", "Suzanne Collins", 10.99, "book.fill"),
                ("The Giver", "Lois Lowry", 9.49, "book.fill"),
                ("Holes", "Louis Sachar", 8.99, "book.fill"),
                ("A Wrinkle in Time", "Madeleine L'Engle", 7.99, "book.fill")
            ]
        }
    }

    func extractOfferDetails() {
        guard let body = card.body else { return }

        // Extract first HTTP/HTTPS URL
        if let url = extractURL(from: body) {
            offerUrl = url
            Logger.info("Detected offer URL: \(url)", category: .action)
        }

        // Extract promo code patterns (CODE:, USE:, PROMO:, etc.)
        if let code = extractPromoCode(from: "\(card.title) \(card.summary) \(body)") {
            promoCode = code
            Logger.info("Detected promo code: \(code)", category: .action)
        }
    }

    func extractURL(from text: String) -> String? {
        // Simple URL regex pattern
        let pattern = "(https?://[^\\s]+)"
        if let regex = try? NSRegularExpression(pattern: pattern, options: []),
           let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)) {
            if let range = Range(match.range, in: text) {
                var urlString = String(text[range])
                // Clean up trailing punctuation
                urlString = urlString.trimmingCharacters(in: CharacterSet(charactersIn: ".,!?;:)"))
                return urlString
            }
        }
        return nil
    }

    func extractPromoCode(from text: String) -> String? {
        // Common promo code patterns
        let patterns = [
            "(?:CODE|PROMO|USE|PROMOCODE):\\s*([A-Z0-9]{4,20})",
            "(?:code|promo|use)\\s+([A-Z0-9]{4,20})",
            "with code\\s+([A-Z0-9]{4,20})"
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
               let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)) {
                if let codeRange = Range(match.range(at: 1), in: text) {
                    return String(text[codeRange])
                }
            }
        }

        return nil
    }

    func openOfferWebsite() {
        guard let urlString = offerUrl, let url = URL(string: urlString) else {
            errorMessage = "No offer URL found"
            return
        }

        // If there's a promo code, copy it to clipboard first
        if let code = promoCode {
            UIPasteboard.general.string = code
            Logger.info("Copied promo code to clipboard: \(code)", category: .action)

            let impact = UINotificationFeedbackGenerator()
            impact.notificationOccurred(.success)
        }

        // Open in Safari
        UIApplication.shared.open(url)

        // Dismiss modal after short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isPresented = false
        }
    }

    func purchaseItem() async {
        isAddingToCart = true
        errorMessage = nil

        do {
            // Call shopping cart API
            let response = try await ShoppingCartService.shared.addToCart(
                userId: "user-123", // TODO: Replace with actual user ID
                emailId: card.id,
                productUrl: nil, // EmailCard doesn't have productUrl field
                productName: card.title,
                productImage: card.productImageUrl,
                price: card.salePrice ?? 0.0,
                originalPrice: card.originalPrice,
                quantity: quantity,
                merchant: card.store,
                sku: nil,
                category: nil,
                expiresAt: nil // TODO: Parse expiration date if available
            )

            // Success!
            await MainActor.run {
                isAddingToCart = false
                showPurchaseSuccess = true

                let impact = UINotificationFeedbackGenerator()
                impact.notificationOccurred(.success)

                Logger.info("Added to cart: \(response.item.productName)", category: .action)
                Logger.info("📊 Cart summary: \(response.summary.itemCount) items, $\(response.summary.subtotal) total", category: .action)
            }

            // Auto-dismiss after success
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            await MainActor.run {
                isPresented = false
            }

        } catch {
            await MainActor.run {
                isAddingToCart = false
                errorMessage = "Failed to add to cart. Please try again."
                Logger.error("Add to cart failed: \(error.localizedDescription)", category: .action)
            }
        }
    }

    func saveDeal() {
        viewModel.toggleSavedDeal(for: card.id)
        showSaveSuccess = true

        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isPresented = false
        }
    }
}

