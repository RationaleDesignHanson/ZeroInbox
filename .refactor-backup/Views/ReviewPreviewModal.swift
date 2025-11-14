import SwiftUI
import SafariServices

/**
 * ReviewPreviewModal
 * Shows product review info before opening review page
 * Framework-compliant: Shows product details and rating options
 */

struct ReviewPreviewModal: View {
    let card: EmailCard
    let productName: String
    let reviewUrl: String
    @Binding var isPresented: Bool
    
    @State private var rating: Int = 0
    @State private var showingSafari = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Write Review")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    Text("Share your experience")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.title2)
                }
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.orange, Color.orange.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            
            Divider()
            
            // Content
            ScrollView {
                VStack(spacing: 24) {
                    // Product info
                    VStack(spacing: 12) {
                        if let imageUrl = card.productImageUrl, let url = URL(string: imageUrl) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 120)
                            } placeholder: {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 120)
                            }
                            .cornerRadius(12)
                        }
                        
                        Text(productName)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                        
                        if let store = card.store {
                            Text("from \(store)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Quick star rating
                    VStack(spacing: 12) {
                        Text("Quick Rating")
                            .font(.headline)
                        
                        HStack(spacing: 8) {
                            ForEach(1...5, id: \.self) { star in
                                Button {
                                    rating = star
                                    HapticFeedback.light()
                                } label: {
                                    Image(systemName: star <= rating ? "star.fill" : "star")
                                        .font(.title)
                                        .foregroundColor(star <= rating ? .yellow : .gray.opacity(0.3))
                                }
                            }
                        }
                        
                        if rating > 0 {
                            Text(ratingText(rating))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)
                    
                    // Info box
                    HStack(spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Write Full Review")
                                .font(.subheadline.bold())
                            Text("Continue to write a detailed review and share photos")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(12)
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        Button {
                            openReviewPage()
                        } label: {
                            HStack {
                                Image(systemName: "square.and.pencil")
                                Text("Write Full Review")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        
                        if rating > 0 {
                            Button {
                                submitQuickRating()
                            } label: {
                                HStack {
                                    Image(systemName: "star.fill")
                                    Text("Submit \(rating)-Star Rating")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.yellow)
                                .foregroundColor(.black)
                                .cornerRadius(12)
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Color(white: 0.98))
        }
        .sheet(isPresented: $showingSafari) {
            if let url = URL(string: reviewUrl) {
                SafariView(url: url)
            }
        }
    }
    
    private func openReviewPage() {
        showingSafari = true
        HapticFeedback.light()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isPresented = false
        }
    }
    
    private func submitQuickRating() {
        // TODO: Submit rating to backend API
        Logger.info("✅ Submitted quick rating: \(rating) stars for \(productName)", category: .app)
        HapticFeedback.success()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isPresented = false
        }
    }
    
    private func ratingText(_ rating: Int) -> String {
        switch rating {
        case 1: return "Poor"
        case 2: return "Fair"
        case 3: return "Good"
        case 4: return "Very Good"
        case 5: return "Excellent"
        default: return ""
        }
    }
}

