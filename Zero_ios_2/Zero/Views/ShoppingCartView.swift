import SwiftUI

struct ShoppingCartView: View {
    @SwiftUI.Environment(\.presentationMode) var presentationMode
    @State private var cartItems: [CartItem] = []
    @State private var cartSummary: CartSummary?
    @State private var isLoading = false
    @State private var errorMessage: String?

    let userId = AuthContext.getUserId()

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                if isLoading {
                    ProgressView("Loading cart...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .foregroundColor(.white)
                } else if let errorMessage = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            Task {
                                await loadCart()
                            }
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(DesignTokens.Radius.button)
                    }
                    .padding()
                } else if cartItems.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "cart")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(DesignTokens.Opacity.overlayStrong))
                        Text("Your cart is empty")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        Text("Add items from your emails to get started")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Cart Summary
                            if let summary = cartSummary {
                                VStack(spacing: 12) {
                                    HStack {
                                        Text("\(summary.itemCount) Items")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        Spacer()
                                        VStack(alignment: .trailing, spacing: 4) {
                                            Text("$\(String(format: "%.2f", summary.subtotal))")
                                                .font(.title2.bold())
                                                .foregroundColor(.white)
                                            if summary.totalSavings > 0 {
                                                Text("Save $\(String(format: "%.2f", summary.totalSavings))")
                                                    .font(.caption)
                                                    .foregroundColor(.green)
                                            }
                                        }
                                    }

                                    // Expiring items warning
                                    if !summary.expiringItems.isEmpty {
                                        VStack(alignment: .leading, spacing: 8) {
                                            HStack {
                                                Image(systemName: "clock.fill")
                                                    .foregroundColor(.orange)
                                                Text("\(summary.expiringItems.count) item(s) expiring soon")
                                                    .font(.subheadline.bold())
                                                    .foregroundColor(.white)
                                            }
                                            ForEach(summary.expiringItems, id: \.id) { item in
                                                Text("\(item.productName) - \(item.hoursUntilExpiration)h left")
                                                    .font(.caption)
                                                    .foregroundColor(.white.opacity(DesignTokens.Opacity.textTertiary))
                                            }
                                        }
                                        .padding()
                                        .background(Color.orange.opacity(DesignTokens.Opacity.overlayLight))
                                        .cornerRadius(DesignTokens.Radius.button)
                                    }
                                }
                                .padding()
                                .background(Color.white.opacity(DesignTokens.Opacity.glassLight))
                                .cornerRadius(DesignTokens.Radius.card)
                            }

                            // Cart Items
                            ForEach(cartItems) { item in
                                CartItemRow(item: item, onRemove: {
                                    Task {
                                        await removeItem(itemId: item.id)
                                    }
                                })
                            }

                            // Checkout Button
                            if !cartItems.isEmpty {
                                Button {
                                    // TODO: Implement checkout
                                    Logger.info("Checkout tapped", category: .app)
                                } label: {
                                    HStack {
                                        Image(systemName: "creditcard.fill")
                                        Text("Checkout")
                                            .font(.headline)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(DesignTokens.Radius.button)
                                }
                                .padding(.top, 20)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Shopping Cart")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .task {
            await loadCart()
        }
    }

    func loadCart() async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await ShoppingCartService.shared.getCart(userId: userId)
            await MainActor.run {
                cartItems = response.cart
                cartSummary = response.summary
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load cart: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }

    func removeItem(itemId: String) async {
        do {
            try await ShoppingCartService.shared.removeItem(userId: userId, itemId: itemId)
            await loadCart() // Reload cart after removal
        } catch {
            await MainActor.run {
                errorMessage = "Failed to remove item"
            }
        }
    }
}

struct CartItemRow: View {
    let item: CartItem
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Product Image
            if let imageUrl = item.productImage, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .clipped()
                        .cornerRadius(DesignTokens.Radius.button)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(DesignTokens.Opacity.overlayMedium))
                        .frame(width: 80, height: 80)
                        .cornerRadius(DesignTokens.Radius.button)
                }
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(DesignTokens.Opacity.overlayMedium))
                    .frame(width: 80, height: 80)
                    .cornerRadius(DesignTokens.Radius.button)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.white.opacity(DesignTokens.Opacity.overlayStrong))
                    )
            }

            // Product Info
            VStack(alignment: .leading, spacing: 6) {
                Text(item.productName)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .lineLimit(2)

                if let merchant = item.merchant {
                    Text(merchant)
                        .font(.caption)
                        .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))
                }

                HStack(spacing: 8) {
                    Text("$\(String(format: "%.2f", item.price))")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)

                    if let originalPrice = item.originalPrice, originalPrice > item.price {
                        Text("$\(String(format: "%.2f", originalPrice))")
                            .font(.caption)
                            .foregroundColor(.white.opacity(DesignTokens.Opacity.overlayStrong))
                            .strikethrough()
                    }

                    if item.savings > 0 {
                        Text("Save $\(String(format: "%.2f", item.savings))")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }

                Text("Qty: \(item.quantity)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
            }

            Spacer()

            // Remove Button
            Button(action: onRemove) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .font(.title3)
            }
        }
        .padding()
        .background(Color.white.opacity(DesignTokens.Opacity.glassLight))
        .cornerRadius(DesignTokens.Radius.card)
    }
}
