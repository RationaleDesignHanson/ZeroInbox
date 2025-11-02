import SwiftUI

struct WriteReviewModal: View {
    let card: EmailCard
    let productName: String
    let reviewLink: String
    let context: [String: Any]
    @Binding var isPresented: Bool

    @State private var rating: Int = 0
    @State private var reviewText: String = ""
    @State private var selectedTags: Set<String> = []
    @State private var showSuccess = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var isSubmitting = false

    // Extract optional context
    var orderDate: String? {
        context["orderDate"] as? String
    }

    var productImage: String? {
        context["productImage"] as? String
    }

    var merchant: String? {
        context["merchant"] as? String
    }

    let reviewTags = ["Quality", "Value", "Service", "Shipping", "Packaging"]
    let characterLimit = 500
    let characterMinimum = 50

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
                    // Header with product info
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.inline) {
                        HStack(spacing: DesignTokens.Spacing.section) {
                            Image(systemName: "star.square.fill")
                                .font(.largeTitle)
                                .foregroundColor(.yellow)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Write Review")
                                    .font(.title2.bold())
                                    .foregroundColor(DesignTokens.Colors.textPrimary)

                                Text(productName)
                                    .font(.subheadline)
                                    .foregroundColor(DesignTokens.Colors.textSubtle)
                                    .lineLimit(2)
                            }
                        }

                        if let merchant = merchant {
                            Text("from \(merchant)")
                                .font(.caption)
                                .foregroundColor(DesignTokens.Colors.textSubtle)
                        }

                        if let orderDate = orderDate {
                            Text("Purchased: \(orderDate)")
                                .font(.caption)
                                .foregroundColor(DesignTokens.Colors.textSubtle)
                        }
                    }

                    Divider()
                        .background(Color.white.opacity(0.3))

                    // Star rating selector
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.component) {
                        Text("Rating")
                            .font(.headline)
                            .foregroundColor(DesignTokens.Colors.textPrimary)

                        HStack(spacing: DesignTokens.Spacing.component) {
                            ForEach(1...5, id: \.self) { star in
                                Button {
                                    rating = star
                                    let impact = UIImpactFeedbackGenerator(style: .light)
                                    impact.impactOccurred()
                                } label: {
                                    Image(systemName: star <= rating ? "star.fill" : "star")
                                        .font(.system(size: 36))
                                        .foregroundColor(star <= rating ? .yellow : .white.opacity(0.3))
                                }
                            }
                        }

                        if rating > 0 {
                            Text(ratingDescription(for: rating))
                                .font(.caption)
                                .foregroundColor(DesignTokens.Colors.textSubtle)
                        }
                    }

                    Divider()
                        .background(Color.white.opacity(0.3))

                    // Review text editor
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.component) {
                        HStack {
                            Text("Your Review")
                                .font(.headline)
                                .foregroundColor(DesignTokens.Colors.textPrimary)

                            Spacer()

                            Text("\(reviewText.count)/\(characterLimit)")
                                .font(.caption)
                                .foregroundColor(reviewText.count >= characterMinimum ? .green : .white.opacity(0.5))
                        }

                        TextEditor(text: $reviewText)
                            .frame(height: 150)
                            .padding(DesignTokens.Spacing.inline)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(DesignTokens.Radius.chip)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                            .onChange(of: reviewText) { oldValue, newValue in
                                if newValue.count > characterLimit {
                                    reviewText = String(newValue.prefix(characterLimit))
                                }
                            }

                        Text("Minimum \(characterMinimum) characters")
                            .font(.caption)
                            .foregroundColor(DesignTokens.Colors.textSubtle)
                    }

                    Divider()
                        .background(Color.white.opacity(0.3))

                    // Category tags
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.component) {
                        Text("Categories (Optional)")
                            .font(.headline)
                            .foregroundColor(DesignTokens.Colors.textPrimary)

                        FlowLayout(spacing: DesignTokens.Spacing.inline) {
                            ForEach(reviewTags, id: \.self) { tag in
                                Button {
                                    if selectedTags.contains(tag) {
                                        selectedTags.remove(tag)
                                    } else {
                                        selectedTags.insert(tag)
                                    }
                                } label: {
                                    Text(tag)
                                        .font(.subheadline)
                                        .padding(.horizontal, DesignTokens.Spacing.component)
                                        .padding(.vertical, DesignTokens.Spacing.inline)
                                        .background(selectedTags.contains(tag) ? Color.blue : Color.white.opacity(0.1))
                                        .foregroundColor(DesignTokens.Colors.textPrimary)
                                        .cornerRadius(DesignTokens.Radius.container)
                                }
                            }
                        }
                    }

                    // Action buttons
                    VStack(spacing: DesignTokens.Spacing.component) {
                        Button {
                            submitReview()
                        } label: {
                            HStack {
                                if isSubmitting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "paperplane.fill")
                                    Text("Submit Review")
                                        .font(.headline)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(canSubmit ? Color.green : Color.gray.opacity(0.3))
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                            .cornerRadius(DesignTokens.Radius.button)
                        }
                        .disabled(!canSubmit || isSubmitting)

                        Button {
                            snoozeReview()
                        } label: {
                            HStack {
                                Image(systemName: "clock.fill")
                                Text("Remind Me Later")
                                    .font(.subheadline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange.opacity(0.3))
                            .foregroundColor(.orange)
                            .cornerRadius(DesignTokens.Radius.button)
                        }

                        if showSuccess {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Review submitted!")
                                    .foregroundColor(.green)
                                    .font(.headline.bold())
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(DesignTokens.Radius.button)
                        }

                        if showError, let error = errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text(error)
                                    .foregroundColor(.red)
                                    .font(.caption)
                            }
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(DesignTokens.Radius.chip)
                        }
                    }
                    .padding(.top, 20)
                }
                .padding(DesignTokens.Spacing.card)
            }
        }
    }

    var canSubmit: Bool {
        rating > 0 && reviewText.count >= characterMinimum
    }

    func ratingDescription(for rating: Int) -> String {
        switch rating {
        case 1: return "Poor"
        case 2: return "Fair"
        case 3: return "Good"
        case 4: return "Very Good"
        case 5: return "Excellent"
        default: return ""
        }
    }

    func submitReview() {
        isSubmitting = true

        // Simulated review submission
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isSubmitting = false
            showSuccess = true

            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.success)

            Logger.info("Review submitted: \(productName), Rating: \(rating)", category: .action)

            // Analytics
            AnalyticsService.shared.log("review_submitted", properties: [
                "product_name": productName,
                "rating": rating,
                "review_length": reviewText.count,
                "tags_selected": Array(selectedTags),
                "merchant": merchant ?? "Unknown"
            ])

            // Open review link if available
            if !reviewLink.isEmpty, let url = URL(string: reviewLink) {
                UIApplication.shared.open(url)
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                isPresented = false
            }
        }
    }

    func snoozeReview() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        Logger.info("Review snoozed: \(productName)", category: .action)

        AnalyticsService.shared.log("review_snoozed", properties: [
            "product_name": productName,
            "merchant": merchant ?? "Unknown"
        ])

        isPresented = false
    }
}

// Simple flow layout for tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: result.positions[index], proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize
        var positions: [CGPoint]

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var positions: [CGPoint] = []
            var size: CGSize = .zero
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let subviewSize = subview.sizeThatFits(.unspecified)

                if currentX + subviewSize.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: currentX, y: currentY))
                currentX += subviewSize.width + spacing
                lineHeight = max(lineHeight, subviewSize.height)
                size.width = max(size.width, currentX - spacing)
            }

            size.height = currentY + lineHeight
            self.size = size
            self.positions = positions
        }
    }
}
