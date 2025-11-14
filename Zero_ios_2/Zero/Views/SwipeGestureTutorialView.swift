import SwiftUI

/// Reusable swipe gesture tutorial view
/// Shows all 4 gestures: Right (Take Action), Left (Mark as Read), Down (Snooze), Up (Choose Action)
struct SwipeGestureTutorialView: View {
    var showTitle: Bool = true
    var showFootnote: Bool = true

    var body: some View {
        VStack(spacing: 16) {
            if showTitle {
                Text("Swipe Gestures")
                    .font(.title.bold())
                    .foregroundColor(.white)
            }

            // Three gesture types
            VStack(spacing: 12) {
                // LEFT SWIPE - Mark as Read
                HStack(spacing: 12) {
                    Image(systemName: "arrow.left")
                        .font(.title2)
                        .foregroundColor(.blue)
                        .frame(width: 40)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Swipe Left")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Mark as Read")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
                    }
                    Spacer()
                }
                .padding()
                .background(Color.blue.opacity(DesignTokens.Opacity.overlayLight))
                .cornerRadius(DesignTokens.Radius.button)

                // RIGHT SWIPE - Take Action
                HStack(spacing: 12) {
                    Image(systemName: "arrow.right")
                        .font(.title2)
                        .foregroundColor(.green)
                        .frame(width: 40)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Swipe Right")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Take Action")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
                    }
                    Spacer()
                }
                .padding()
                .background(Color.green.opacity(DesignTokens.Opacity.overlayLight))
                .cornerRadius(DesignTokens.Radius.button)

                // DOWN SWIPE - Snooze
                HStack(spacing: 12) {
                    Image(systemName: "arrow.down")
                        .font(.title2)
                        .foregroundColor(.purple)
                        .frame(width: 40)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Swipe Down")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Snooze")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
                    }
                    Spacer()
                }
                .padding()
                .background(Color.purple.opacity(DesignTokens.Opacity.overlayLight))
                .cornerRadius(DesignTokens.Radius.button)

                // UP SWIPE - Choose Action
                HStack(spacing: 12) {
                    Image(systemName: "arrow.up")
                        .font(.title2)
                        .foregroundColor(.orange)
                        .frame(width: 40)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Swipe Up")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Choose Action")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
                    }
                    Spacer()
                }
                .padding()
                .background(Color.orange.opacity(DesignTokens.Opacity.overlayLight))
                .cornerRadius(DesignTokens.Radius.button)
            }
            .padding(.horizontal)

            if showFootnote {
                Text("Urgent emails will ask for confirmation before marking as read")
                    .font(.caption)
                    .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [
                Color(red: 0.1, green: 0.1, blue: 0.15),
                Color(red: 0.15, green: 0.15, blue: 0.2)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        SwipeGestureTutorialView()
    }
}
