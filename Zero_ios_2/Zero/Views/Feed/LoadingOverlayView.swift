import SwiftUI

/// Loading overlay view shown while fetching emails
struct LoadingOverlayView: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(DesignTokens.Opacity.overlayMedium)
                .ignoresSafeArea()

            // Loading spinner
            VStack(spacing: DesignTokens.Spacing.card) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)

                Text("Loading emails...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .opacity(isAnimating ? 1.0 : 0.6)
            }
            .padding(DesignTokens.Spacing.card)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.container)
                    .fill(Color.white.opacity(0.15))
                    .shadow(color: .black.opacity(DesignTokens.Opacity.overlayLight), radius: 10, x: 0, y: 4)
            )
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Preview
#if DEBUG
struct LoadingOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            LinearGradient(
                colors: [.blue, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            LoadingOverlayView()
        }
    }
}
#endif
