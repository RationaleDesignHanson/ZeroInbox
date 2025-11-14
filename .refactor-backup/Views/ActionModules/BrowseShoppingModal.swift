import SwiftUI

struct BrowseShoppingModal: View {
    let card: EmailCard
    let context: [String: Any]
    @Binding var isPresented: Bool

    @State private var selectedCategory: String? = nil
    @State private var sortOption: SortOption = .relevance
    @State private var searchText: String = ""
    @State private var showSuccess = false

    // Extract products from context
    var products: [ProductItem] {
        if let productArray = context["products"] as? [[String: Any]] {
            return productArray.compactMap { dict in
                guard let name = dict["name"] as? String,
                      let price = dict["price"] as? String else {
                    return nil
                }
                return ProductItem(
                    name: name,
                    price: price,
                    imageUrl: dict["imageUrl"] as? String,
                    productUrl: dict["productUrl"] as? String,
                    rating: dict["rating"] as? String
                )
            }
        }
        // Fallback demo products if none provided
        return [
            ProductItem(name: "Classic White T-Shirt", price: "$24.99", imageUrl: nil, productUrl: nil, rating: "4.5"),
            ProductItem(name: "Blue Denim Jeans", price: "$59.99", imageUrl: nil, productUrl: nil, rating: "4.8"),
            ProductItem(name: "Running Shoes", price: "$89.99", imageUrl: nil, productUrl: nil, rating: "4.6"),
            ProductItem(name: "Cotton Hoodie", price: "$44.99", imageUrl: nil, productUrl: nil, rating: "4.7"),
            ProductItem(name: "Canvas Backpack", price: "$39.99", imageUrl: nil, productUrl: nil, rating: "4.4")
        ]
    }

    var merchant: String {
        context["merchant"] as? String ?? card.company?.name ?? "Shop"
    }

    let categories = ["All", "Clothing", "Electronics", "Home", "Beauty", "Sports"]

    enum SortOption: String, CaseIterable {
        case relevance = "Relevance"
        case priceLow = "Price: Low to High"
        case priceHigh = "Price: High to Low"
        case rating = "Rating"
    }

    var filteredProducts: [ProductItem] {
        var filtered = products

        // Filter by category
        if let category = selectedCategory, category != "All" {
            filtered = filtered.filter { $0.name.localizedCaseInsensitiveContains(category) }
        }

        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }

        // Sort
        switch sortOption {
        case .relevance:
            break // Keep original order
        case .priceLow:
            filtered = filtered.sorted { extractPrice($0.price) < extractPrice($1.price) }
        case .priceHigh:
            filtered = filtered.sorted { extractPrice($0.price) > extractPrice($1.price) }
        case .rating:
            filtered = filtered.sorted { extractRating($0.rating) > extractRating($1.rating) }
        }

        return filtered
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
            .padding()

            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.card) {
                    // Header
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.inline) {
                        HStack {
                            Image(systemName: "cart.fill")
                                .font(.largeTitle)
                                .foregroundColor(.blue)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Browse Products")
                                    .font(.title2.bold())
                                    .foregroundColor(DesignTokens.Colors.textPrimary)

                                Text("from \(merchant)")
                                    .font(.subheadline)
                                    .foregroundColor(DesignTokens.Colors.textSubtle)
                            }
                        }
                    }

                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(DesignTokens.Colors.textSubtle)
                        TextField("Search products...", text: $searchText)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                    }
                    .padding(DesignTokens.Spacing.component)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(10)

                    // Category filter chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DesignTokens.Spacing.inline) {
                            ForEach(categories, id: \.self) { category in
                                Button {
                                    if selectedCategory == category {
                                        selectedCategory = nil
                                    } else {
                                        selectedCategory = category
                                    }
                                } label: {
                                    Text(category)
                                        .font(.subheadline)
                                        .padding(.horizontal, DesignTokens.Spacing.section)
                                        .padding(.vertical, DesignTokens.Spacing.inline)
                                        .background(selectedCategory == category ? Color.blue : Color.white.opacity(0.1))
                                        .foregroundColor(DesignTokens.Colors.textPrimary)
                                        .cornerRadius(20)
                                }
                            }
                        }
                    }

                    // Sort options
                    HStack {
                        Text("Sort by:")
                            .font(.caption)
                            .foregroundColor(DesignTokens.Colors.textSubtle)

                        Menu {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Button {
                                    sortOption = option
                                } label: {
                                    HStack {
                                        Text(option.rawValue)
                                        if sortOption == option {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Text(sortOption.rawValue)
                                    .font(.caption)
                                    .foregroundColor(DesignTokens.Colors.textPrimary)
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(DesignTokens.Colors.textSubtle)
                            }
                            .padding(.horizontal, DesignTokens.Spacing.component)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(DesignTokens.Spacing.inline)
                        }
                    }

                    Divider()
                        .background(Color.white.opacity(0.3))

                    // Products grid
                    if filteredProducts.isEmpty {
                        VStack(spacing: DesignTokens.Spacing.component) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 48))
                                .foregroundColor(DesignTokens.Colors.textSubtle)
                            Text("No products found")
                                .font(.headline)
                                .foregroundColor(DesignTokens.Colors.textSubtle)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: DesignTokens.Spacing.section) {
                            ForEach(filteredProducts) { product in
                                ProductCardView(product: product) {
                                    viewProduct(product)
                                }
                            }
                        }
                    }

                    if showSuccess {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Product opened!")
                                .foregroundColor(.green)
                                .font(.headline.bold())
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(DesignTokens.Radius.button)
                    }
                }
                .padding(DesignTokens.Spacing.card)
            }
        }
    }

    func extractPrice(_ priceString: String?) -> Double {
        guard let priceString = priceString else { return 0 }
        let cleanedString = priceString.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")
        return Double(cleanedString) ?? 0
    }

    func extractRating(_ ratingString: String?) -> Double {
        guard let ratingString = ratingString else { return 0 }
        return Double(ratingString) ?? 0
    }

    func viewProduct(_ product: ProductItem) {
        if let urlString = product.productUrl, let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }

        showSuccess = true

        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        Logger.info("Product viewed: \(product.name)", category: .action)

        AnalyticsService.shared.log("product_viewed", properties: [
            "product_name": product.name,
            "product_price": product.price,
            "merchant": merchant
        ])

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showSuccess = false
        }
    }
}

// MARK: - Product Item Model
struct ProductItem: Identifiable {
    let id = UUID()
    let name: String
    let price: String
    let imageUrl: String?
    let productUrl: String?
    let rating: String?
}

// MARK: - Product Card View
struct ProductCardView: View {
    let product: ProductItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.inline) {
                // Product image placeholder
                ZStack {
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .aspectRatio(1, contentMode: .fit)

                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundColor(DesignTokens.Colors.textSubtle)
                }
                .cornerRadius(DesignTokens.Radius.button)

                // Product name
                Text(product.name)
                    .font(.subheadline)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Rating (if available)
                if let rating = product.rating {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                        Text(rating)
                            .font(.caption)
                            .foregroundColor(DesignTokens.Colors.textSubtle)
                    }
                }

                // Price
                Text(product.price)
                    .font(.headline)
                    .foregroundColor(.green)
            }
            .padding(DesignTokens.Spacing.component)
            .background(Color.white.opacity(0.05))
            .cornerRadius(DesignTokens.Radius.button)
        }
    }
}
