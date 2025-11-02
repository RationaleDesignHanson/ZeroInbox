import SwiftUI

// MARK: - Scheduled Purchase Modal
struct ScheduledPurchaseModal: View {
    @StateObject private var viewModel: ScheduledPurchaseViewModel
    @Binding var isPresented: Bool

    let card: EmailCard
    let action: EmailAction

    init(card: EmailCard, action: EmailAction, isPresented: Binding<Bool>) {
        self.card = card
        self.action = action
        self._isPresented = isPresented
        _viewModel = StateObject(wrappedValue: ScheduledPurchaseViewModel(card: card, action: action))
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: DesignTokens.Spacing.card) {
                        // Product Info Section
                        productInfoSection

                        // Schedule Section
                        scheduleSection

                        // Confirmation Section
                        if viewModel.showConfirmation {
                            confirmationSection
                        }

                        Spacer(minLength: 100)
                    }
                    .padding(DesignTokens.Spacing.card)
                }

                // Bottom Action Button
                VStack {
                    Spacer()
                    bottomActionButton
                }
            }
            .navigationTitle("Schedule Purchase")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                }
            }
        }
        .alert("Purchase Scheduled!", isPresented: $viewModel.showSuccessAlert) {
            Button("Done") {
                isPresented = false
            }
        } message: {
            Text("We'll notify you on \(viewModel.formattedScheduledDate) to complete your purchase.")
        }
        .alert("Error", isPresented: $viewModel.showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }

    // MARK: - Product Info Section
    private var productInfoSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.section) {
            Text("Product")
                .font(.headline)
                .foregroundColor(DesignTokens.Colors.textSubtle)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.component) {
                // Product name from email
                if let productName = extractProductName() {
                    Text(productName)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                }

                // Sender
                if let sender = card.sender {
                    HStack(spacing: DesignTokens.Spacing.inline) {
                        Circle()
                            .fill(Color.purple.opacity(0.3))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Text(sender.initial)
                                    .foregroundColor(.purple)
                                    .font(.system(size: 14, weight: .semibold))
                            )

                        Text(sender.name)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                }

                // Product URL
                if let productUrl = action.context?["productUrl"] {
                    HStack(spacing: 4) {
                        Image(systemName: "link")
                            .font(.caption)
                        Text(formatURL(productUrl))
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .foregroundColor(.blue.opacity(0.8))
                }

                // Price info if available
                if let originalPrice = card.originalPrice {
                    HStack(spacing: DesignTokens.Spacing.inline) {
                        if let salePrice = card.salePrice {
                            Text("$\(String(format: "%.2f", originalPrice))")
                                .strikethrough()
                                .foregroundColor(DesignTokens.Colors.textSubtle)
                            Text("$\(String(format: "%.2f", salePrice))")
                                .foregroundColor(.green)
                                .fontWeight(.semibold)

                            if let discount = card.discount {
                                Text("\(discount)% off")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.green.opacity(0.2))
                                    .cornerRadius(4)
                            }
                        } else {
                            Text("$\(String(format: "%.2f", originalPrice))")
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                                .fontWeight(.semibold)
                        }
                    }
                }

                // Limited edition badge
                if card.urgent == true || card.expiresIn != nil {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.caption)
                        Text("Limited Time")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(DesignTokens.Spacing.inline)
                }
            }
            .padding(DesignTokens.Spacing.section)
            .background(Color.white.opacity(0.05))
            .cornerRadius(DesignTokens.Radius.button)
        }
    }

    // MARK: - Schedule Section
    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.section) {
            Text("When")
                .font(.headline)
                .foregroundColor(DesignTokens.Colors.textSubtle)

            VStack(spacing: DesignTokens.Spacing.section) {
                // Sale date display
                if let saleDate = action.context?["saleDate"] {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.purple)
                        Text(saleDate)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                        Spacer()
                    }
                    .padding(DesignTokens.Spacing.section)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(DesignTokens.Radius.button)
                }

                // Time info
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.inline) {
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.blue)
                        Text("We'll notify you when the product goes on sale")
                            .font(.subheadline)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }

                    Text("You'll be able to complete the purchase in your browser")
                        .font(.caption)
                        .foregroundColor(DesignTokens.Colors.textSubtle)
                }
                .padding(DesignTokens.Spacing.section)
                .background(Color.white.opacity(0.05))
                .cornerRadius(DesignTokens.Radius.button)
            }
        }
    }

    // MARK: - Confirmation Section
    private var confirmationSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.section) {
            Text("Confirmation")
                .font(.headline)
                .foregroundColor(DesignTokens.Colors.textSubtle)

            VStack(spacing: DesignTokens.Spacing.component) {
                confirmationRow(icon: "bell.fill", text: "Notification at scheduled time", color: .green)
                confirmationRow(icon: "safari", text: "Opens product page automatically", color: .blue)
                confirmationRow(icon: "hand.raised.fill", text: "You complete checkout manually", color: .orange)
                confirmationRow(icon: "lock.fill", text: "No payment info stored", color: .purple)
            }
            .padding(DesignTokens.Spacing.section)
            .background(Color.white.opacity(0.05))
            .cornerRadius(DesignTokens.Radius.button)
        }
    }

    private func confirmationRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: DesignTokens.Spacing.component) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundColor(DesignTokens.Colors.textSecondary)
            Spacer()
        }
    }

    // MARK: - Bottom Action Button
    private var bottomActionButton: some View {
        Button(action: {
            if viewModel.showConfirmation {
                viewModel.schedulePurchase()
            } else {
                withAnimation(.spring(response: 0.3)) {
                    viewModel.showConfirmation = true
                }
            }
        }) {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text(viewModel.showConfirmation ? "Confirm Schedule" : "Schedule Purchase")
                }
            }
        }
        .buttonStyle(.gradientLifestyle)
        .padding(.horizontal, DesignTokens.Spacing.card)
        .padding(.bottom, DesignTokens.Spacing.card)
        .disabled(viewModel.isLoading)
        .opacity(viewModel.isLoading ? 0.5 : 1.0)
    }

    // MARK: - Helper Functions
    private func extractProductName() -> String? {
        // Try to get from action context first
        if let productName = action.context?["productName"] {
            return productName
        }

        // Fall back to card title
        return card.title
    }

    private func formatURL(_ urlString: String) -> String {
        if let url = URL(string: urlString) {
            return url.host ?? urlString
        }
        return urlString
    }
}

// MARK: - View Model
class ScheduledPurchaseViewModel: ObservableObject {
    @Published var showConfirmation = false
    @Published var isLoading = false
    @Published var showSuccessAlert = false
    @Published var showErrorAlert = false
    @Published var errorMessage = ""

    private let card: EmailCard
    private let action: EmailAction

    init(card: EmailCard, action: EmailAction) {
        self.card = card
        self.action = action
    }

    var formattedScheduledDate: String {
        guard let saleDate = action.context?["saleDate"] else {
            return "the scheduled date"
        }
        return saleDate
    }

    func schedulePurchase() {
        isLoading = true

        // Extract required data
        guard let productUrl = action.context?["productUrl"],
              let saleDate = action.context?["saleDate"] else {
            errorMessage = "Missing required purchase information"
            showErrorAlert = true
            isLoading = false
            return
        }

        // Convert sale date to ISO8601 format
        // For MVP, we'll use a placeholder future date
        // In production, parse saleDate properly
        let scheduledTime = convertToISO8601(saleDate)

        // Prepare request
        let request = ScheduledPurchaseRequest(
            userId: "current-user", // TODO: Get from auth
            emailId: card.id,
            productName: extractProductName(),
            productUrl: productUrl,
            scheduledTime: scheduledTime,
            timezone: "UTC" // TODO: Get user's timezone
        )

        // Call API
        Task {
            do {
                try await ScheduledPurchaseService.shared.createPurchase(request)

                await MainActor.run {
                    isLoading = false
                    showSuccessAlert = true

                    // Haptic feedback
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }

    private func extractProductName() -> String {
        if let productName = action.context?["productName"] {
            return productName
        }
        return card.title
    }

    private func convertToISO8601(_ dateString: String) -> String {
        // Simple conversion for MVP - parse "31 October" or "Oct 31"
        // In production, use proper date parsing

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d MMMM" // "31 October"

        if let date = dateFormatter.date(from: dateString) {
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.timeZone = TimeZone(identifier: "UTC")

            // Combine with current year and a default time
            var calendar = Calendar.current
            calendar.timeZone = TimeZone(identifier: "UTC")!

            var components = calendar.dateComponents([.month, .day], from: date)
            components.year = Calendar.current.component(.year, from: Date())
            components.hour = 17 // 5 PM UTC as default
            components.minute = 0

            if let fullDate = calendar.date(from: components) {
                return isoFormatter.string(from: fullDate)
            }
        }

        // Fallback: return a date 1 week from now
        let futureDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        let isoFormatter = ISO8601DateFormatter()
        return isoFormatter.string(from: futureDate)
    }
}

// MARK: - API Models
struct ScheduledPurchaseRequest: Codable {
    let userId: String
    let emailId: String
    let productName: String
    let productUrl: String
    let scheduledTime: String
    let timezone: String
}

struct ScheduledPurchaseResponse: Codable {
    let id: String
    let userId: String
    let emailId: String
    let productName: String
    let productUrl: String
    let scheduledTime: String
    let timezone: String
    let status: String
    let variant: String?
    let createdAt: String
    let updatedAt: String
}

// MARK: - API Service
class ScheduledPurchaseService {
    static let shared = ScheduledPurchaseService()

    private let baseURL = "http://localhost:8085/api"

    func createPurchase(_ request: ScheduledPurchaseRequest) async throws {
        guard let url = URL(string: "\(baseURL)/purchases") else {
            throw URLError(.badURL)
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        // Optionally decode and return the response
        _ = try JSONDecoder().decode(ScheduledPurchaseResponse.self, from: data)
    }

    func getUserPurchases(userId: String) async throws -> [ScheduledPurchaseResponse] {
        guard let url = URL(string: "\(baseURL)/purchases/user/\(userId)") else {
            throw URLError(.badURL)
        }

        let (data, _) = try await URLSession.shared.data(from: url)

        let response = try JSONDecoder().decode(PurchasesResponse.self, from: data)
        return response.purchases
    }

    func cancelPurchase(id: String) async throws {
        guard let url = URL(string: "\(baseURL)/purchases/\(id)/cancel") else {
            throw URLError(.badURL)
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"

        let (_, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
}

struct PurchasesResponse: Codable {
    let purchases: [ScheduledPurchaseResponse]
    let count: Int
}

// MARK: - Preview
struct ScheduledPurchaseModal_Previews: PreviewProvider {
    static var previews: some View {
        ScheduledPurchaseModal(
            card: EmailCard(
                id: "preview-1",
                type: .ads,
                state: .unseen,
                priority: .high,
                hpa: "Buy on Oct 31",
                timeAgo: "2h",
                title: "James Jean - Sculpture and print duo",
                summary: "Limited edition Sun Tarot Nebula collection launching October 31",
                metaCTA: "Swipe Right: Schedule Purchase",
                intent: "shopping.future_sale",
                intentConfidence: 1.0,
                suggestedActions: [
                    EmailAction(
                        actionId: "schedule_purchase",
                        displayName: "Buy on Oct 31",
                        actionType: .inApp,
                        isPrimary: true,
                        priority: 1,
                        context: [
                            "saleDate": "31 October",
                            "productUrl": "https://avantarte.com/releases/james-jean-2025",
                            "productName": "James Jean - Sun Tarot Nebula"
                        ]
                    )
                ],
                sender: SenderInfo(name: "Avant Arte", initial: "A", email: nil),
                urgent: true,
                expiresIn: "One week only"
            ),
            action: EmailAction(
                actionId: "schedule_purchase",
                displayName: "Buy on Oct 31",
                actionType: .inApp,
                isPrimary: true,
                priority: 1,
                context: [
                    "saleDate": "31 October",
                    "productUrl": "https://avantarte.com/releases/james-jean-2025",
                    "productName": "James Jean - Sun Tarot Nebula"
                ]
            ),
            isPresented: .constant(true)
        )
        .preferredColorScheme(.dark)
    }
}
