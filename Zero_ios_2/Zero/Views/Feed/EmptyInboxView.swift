import SwiftUI

/// Empty state view shown when there are no cards to display
struct EmptyInboxView: View {
    var body: some View {
        VStack(spacing: 24) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.white.opacity(DesignTokens.Opacity.glassLight))
                    .frame(width: 120, height: 120)

                Image(systemName: "tray")
                    .font(.system(size: 50, weight: .light))
                    .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))
            }

            // Text
            VStack(spacing: 8) {
                Text("All Caught Up!")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)

                Text("No more emails to review")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
            }

            // Subtle animation
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 30))
                .foregroundColor(.green.opacity(DesignTokens.Opacity.textTertiary))
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview
#if DEBUG
struct EmptyInboxView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            LinearGradient(
                colors: [.blue, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            EmptyInboxView()
        }
    }
}
#endif
