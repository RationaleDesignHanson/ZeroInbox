import SwiftUI

/// Loading overlay view shown while fetching emails
struct LoadingOverlayView: View {
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(DesignTokens.Opacity.overlayMedium)
                .ignoresSafeArea()

            // Loading content using reusable component
            LoadingSpinner(text: "Loading emails...", size: .large)
                .padding(DesignTokens.Spacing.card)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.container)
                        .fill(Color.white.opacity(0.15))
                        .shadow(color: .black.opacity(DesignTokens.Opacity.overlayLight), radius: 10, x: 0, y: 4)
                )
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
