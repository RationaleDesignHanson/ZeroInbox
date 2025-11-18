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
            ModalHeader(isPresented: $isPresented)

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
                        .background(Color.white.opacity(DesignTokens.Opacity.overlayMedium))

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
                                        .foregroundColor(star <= rating ? .yellow : .white.opacity(DesignTokens.Opacity.overlayMedium))
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
                        .background(Color.white.opacity(DesignTokens.Opacity.overlayMedium))

                    // Review text editor
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.component) {
                        HStack {
                            Text("Your Review")
                                .font(.headline)
                                .foregroundColor(DesignTokens.Colors.textPrimary)

                            Spacer()

                            Text("\(reviewText.count)/\(characterLimit)")
                                .font(.caption)
                                .foregroundColor(reviewText.count >= characterMinimum ? .green : .white.opacity(DesignTokens.Opacity.overlayStrong))
                        }

                        TextEditor(text: $reviewText)
                            .frame(height: 150)
                            .padding(DesignTokens.Spacing.inline)
                            .background(Color.white.opacity(DesignTokens.Opacity.glassLight))
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
                        .background(Color.white.opacity(DesignTokens.Opacity.overlayMedium))

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
                                        .background(selectedTags.contains(tag) ? Color.blue : Color.white.opacity(DesignTokens.Opacity.glassLight))
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
                            .background(canSubmit ? Color.green : Color.gray.opacity(DesignTokens.Opacity.overlayMedium))
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
                            .background(Color.orange.opacity(DesignTokens.Opacity.overlayMedium))
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
                            .background(Color.green.opacity(DesignTokens.Opacity.overlayLight))
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
                            .background(Color.red.opacity(DesignTokens.Opacity.glassLight))
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
