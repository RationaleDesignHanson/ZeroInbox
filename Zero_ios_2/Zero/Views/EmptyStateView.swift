import SwiftUI

struct EmptyStateView: View {
    let archetype: CardType
    let onRefresh: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: iconName)
                .font(.system(size: 80))
                .foregroundColor(.white.opacity(0.8))
            
            // Title
            Text(title)
                .font(.title.bold())
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            // Message
            Text(message)
                .font(.body)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            // Refresh button
            Button {
                onRefresh()
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Refresh")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.2))
                .cornerRadius(12)
            }
            .padding(.top, 8)
        }
        .padding()
    }
    
    var iconName: String {
        // Binary classification: mail or ads
        switch archetype {
        case .mail: return "envelope.fill"
        case .ads: return "cart.fill.badge.plus"
        }
    }

    var title: String {
        switch archetype {
        case .mail: return "All Caught Up!"
        case .ads: return "No Active Deals"
        }
    }

    var message: String {
        switch archetype {
        case .mail:
            return "All emails have been handled. Great job staying organized!"
        case .ads:
            return "No deals expiring soon. Check back later for new savings!"
        }
    }
}

#Preview("Mail Empty") {
    ZStack {
        LinearGradient(
            colors: [
                Color(red: 0.388, green: 0.6, blue: 0.945),
                Color(red: 0.2, green: 0.714, blue: 0.835)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        EmptyStateView(
            archetype: .mail,
            onRefresh: {}
        )
    }
}

#Preview("Ads Empty") {
    ZStack {
        LinearGradient(
            colors: [
                Color(red: 0.953, green: 0.612, blue: 0.071),
                Color(red: 0.988, green: 0.765, blue: 0.333)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        EmptyStateView(
            archetype: .ads,
            onRefresh: {}
        )
    }
}

