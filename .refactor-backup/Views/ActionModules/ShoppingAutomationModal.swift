import SwiftUI

struct ShoppingAutomationModal: View {
    let card: EmailCard
    let productUrl: String
    let productName: String
    let context: [String: Any]
    @Binding var isPresented: Bool
    @EnvironmentObject var viewModel: EmailViewModel

    @State private var automationState: AutomationState = .initializing
    @State private var checkoutUrl: String? = nil
    @State private var errorMessage: String? = nil
    @State private var automationSteps: [AutomationStep] = []
    @State private var showingWebView = false

    enum AutomationState {
        case initializing
        case detectingPlatform
        case addingToCart
        case navigatingToCheckout
        case success
        case fallback
        case error
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
            .padding(.top, 20)
            .padding(.horizontal)
            .padding(.bottom, DesignTokens.Spacing.inline)

            ScrollView {
                VStack(alignment: .center, spacing: DesignTokens.Spacing.card) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.green.opacity(0.3), Color.green.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)

                        Image(systemName: automationIconName)
                            .font(.system(size: 50))
                            .foregroundColor(automationIconColor)
                    }

                    // Title
                    Text(automationTitle)
                        .font(.title2.bold())
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .multilineTextAlignment(.center)

                    // Product info
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.component) {
                        HStack(spacing: DesignTokens.Spacing.component) {
                            Image(systemName: "cart.fill")
                                .foregroundColor(.green)
                                .font(.title3)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Product")
                                    .font(.caption)
                                    .foregroundColor(DesignTokens.Colors.textSubtle)

                                Text(productName)
                                    .font(.subheadline.bold())
                                    .foregroundColor(DesignTokens.Colors.textPrimary)
                            }
                        }

                        Divider()
                            .background(Color.white.opacity(0.2))

                        HStack(spacing: DesignTokens.Spacing.component) {
                            Image(systemName: "link")
                                .foregroundColor(.blue)
                                .font(.title3)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Store")
                                    .font(.caption)
                                    .foregroundColor(DesignTokens.Colors.textSubtle)

                                Text(extractDomain(from: productUrl))
                                    .font(.subheadline.bold())
                                    .foregroundColor(DesignTokens.Colors.textPrimary)
                            }
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(DesignTokens.Radius.container)

                    // Status message
                    Text(automationStatusMessage)
                        .font(.body)
                        .foregroundColor(DesignTokens.Colors.textSubtle)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    // Progress indicator
                    if automationState == .initializing ||
                       automationState == .detectingPlatform ||
                       automationState == .addingToCart ||
                       automationState == .navigatingToCheckout {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .green))
                            .scaleEffect(1.5)
                            .padding()
                    }

                    // Automation steps
                    if !automationSteps.isEmpty {
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.component) {
                            ForEach(Array(automationSteps.enumerated()), id: \.offset) { index, step in
                                HStack(spacing: DesignTokens.Spacing.component) {
                                    Image(systemName: step.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundColor(step.success ? .green : .red)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(stepDisplayName(step.step))
                                            .font(.subheadline)
                                            .foregroundColor(DesignTokens.Colors.textPrimary)

                                        if let error = step.error {
                                            Text(error)
                                                .font(.caption)
                                                .foregroundColor(.red)
                                        }
                                    }

                                    Spacer()
                                }
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(DesignTokens.Radius.container)
                    }

                    // Error message
                    if let error = errorMessage {
                        HStack(spacing: DesignTokens.Spacing.component) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)

                            Text(error)
                                .font(.subheadline)
                                .foregroundColor(.red)
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(DesignTokens.Radius.container)
                    }

                    // Action buttons - Simplified for fastest purchase decision
                    VStack(spacing: DesignTokens.Spacing.component) {
                        if automationState == .success || automationState == .fallback || automationState == .error {
                            Button {
                                openCheckoutPage()
                            } label: {
                                HStack {
                                    Image(systemName: automationState == .success ? "cart.badge.plus" : "safari")
                                    Text(automationState == .success ? "Complete Purchase" : "View Product")
                                        .font(.headline)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: automationState == .success ?
                                            [Color.green, Color.green.opacity(0.8)] :
                                            [Color.blue, Color.blue.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .cornerRadius(DesignTokens.Radius.button)
                                .shadow(color: (automationState == .success ? Color.green : Color.blue).opacity(0.3), radius: 8, x: 0, y: 4)
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
                    Color(red: 0.1, green: 0.15, blue: 0.2),
                    Color(red: 0.05, green: 0.1, blue: 0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .onAppear {
            startAutomation()
        }
    }

    // MARK: - Computed Properties

    var automationTitle: String {
        switch automationState {
        case .initializing:
            return "Starting Automation"
        case .detectingPlatform:
            return "Detecting Platform"
        case .addingToCart:
            return "Adding to Cart"
        case .navigatingToCheckout:
            return "Navigating to Checkout"
        case .success:
            return "Success!"
        case .fallback:
            return "Manual Checkout"
        case .error:
            return "Automation Failed"
        }
    }

    var automationStatusMessage: String {
        switch automationState {
        case .initializing:
            return "Initializing AI automation..."
        case .detectingPlatform:
            return "Analyzing product page structure..."
        case .addingToCart:
            return "Finding and clicking 'Add to Cart' button..."
        case .navigatingToCheckout:
            return "Navigating to checkout page..."
        case .success:
            return "Successfully added \(productName) to cart! Ready for checkout."
        case .fallback:
            return "Automation unavailable. You can complete checkout manually."
        case .error:
            return "Unable to complete automation. Please try again or checkout manually."
        }
    }

    var automationIconName: String {
        switch automationState {
        case .initializing, .detectingPlatform, .addingToCart, .navigatingToCheckout:
            return "gearshape.2.fill"
        case .success:
            return "checkmark.circle.fill"
        case .fallback:
            return "safari"
        case .error:
            return "exclamationmark.triangle.fill"
        }
    }

    var automationIconColor: Color {
        switch automationState {
        case .initializing, .detectingPlatform, .addingToCart, .navigatingToCheckout:
            return .blue
        case .success:
            return .green
        case .fallback:
            return .orange
        case .error:
            return .red
        }
    }

    // MARK: - Helper Functions

    func extractDomain(from url: String) -> String {
        guard let urlObj = URL(string: url),
              let host = urlObj.host else {
            return url
        }

        // Remove www. prefix if present
        if host.hasPrefix("www.") {
            return String(host.dropFirst(4))
        }

        return host
    }

    func stepDisplayName(_ step: String) -> String {
        switch step {
        case "detect_platform":
            return "Detected e-commerce platform"
        case "create_session":
            return "Created browser session"
        case "navigate_to_product":
            return "Loaded product page"
        case "click_add_to_cart":
            return "Clicked 'Add to Cart'"
        case "click_checkout":
            return "Navigated to checkout"
        case "complete":
            return "Automation complete"
        default:
            return step.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    func startAutomation() {
        automationState = .initializing
        errorMessage = nil
        automationSteps = []
        checkoutUrl = nil

        Logger.info("🤖 Starting shopping automation for: \(productName)", category: .action)

        // Update state to detecting platform
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            automationState = .detectingPlatform
        }

        // Call automation service
        ShoppingAutomationService.shared.automateAddToCart(
            productUrl: productUrl,
            productName: productName
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let automationResult):
                    // Update steps if available
                    if let steps = automationResult.steps {
                        automationSteps = steps
                    }

                    // Store checkout URL
                    checkoutUrl = automationResult.checkoutUrl

                    if automationResult.success {
                        // Success!
                        automationState = .success

                        let impact = UINotificationFeedbackGenerator()
                        impact.notificationOccurred(.success)

                        Logger.info("✅ Shopping automation succeeded!", category: .action)
                    } else {
                        // Fallback mode
                        automationState = .fallback
                        errorMessage = automationResult.message

                        Logger.warning("⚠️ Shopping automation failed, using fallback", category: .action)
                    }

                case .failure(let error):
                    // Error occurred
                    automationState = .error
                    errorMessage = error.localizedDescription
                    checkoutUrl = productUrl // Fallback to product URL

                    Logger.error("❌ Shopping automation error: \(error.localizedDescription)", category: .action)
                }
            }
        }

        // Simulate progress through states (will be overridden by actual completion)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if automationState == .detectingPlatform {
                automationState = .addingToCart
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            if automationState == .addingToCart {
                automationState = .navigatingToCheckout
            }
        }
    }

    func openCheckoutPage() {
        guard let urlString = checkoutUrl,
              let url = URL(string: urlString) else {
            errorMessage = "No checkout URL available"
            return
        }

        Logger.info("🌐 Opening checkout page: \(urlString)", category: .action)

        // Open in Safari
        UIApplication.shared.open(url)

        // Dismiss modal after short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isPresented = false
        }
    }
}
