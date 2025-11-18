import SwiftUI

/// Generic container for bottom sheets
/// Provides consistent structure: handle bar + content + background + corner styling
struct BottomSheetContainer<Content: View, Background: View>: View {
    let maxHeight: CGFloat
    let useGlassmorphic: Bool
    let background: Background
    let content: Content

    init(
        maxHeight: CGFloat = 500,
        useGlassmorphic: Bool = false,
        @ViewBuilder background: () -> Background,
        @ViewBuilder content: () -> Content
    ) {
        self.maxHeight = maxHeight
        self.useGlassmorphic = useGlassmorphic
        self.background = background()
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            SheetHandleBar()
            content
        }
        .frame(maxWidth: .infinity, maxHeight: maxHeight)
        .background(background)
        .applyCornerStyle(useGlassmorphic: useGlassmorphic)
    }
}

// MARK: - Corner Styling Extension

private extension View {
    @ViewBuilder
    func applyCornerStyle(useGlassmorphic: Bool) -> some View {
        if useGlassmorphic {
            self.glassmorphic(opacity: 0.03, cornerRadius: DesignTokens.Radius.card)
        } else {
            self
                .cornerRadius(DesignTokens.Radius.card)
                .shadow(color: .black.opacity(DesignTokens.Opacity.overlayMedium), radius: 20, y: -5)
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 20) {
            // Example 1: Glassmorphic with gradient
            BottomSheetContainer(
                maxHeight: 400,
                useGlassmorphic: true,
                background: {
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                },
                content: {
                    VStack {
                        Text("Glassmorphic Sheet")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        Text("With animated background")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding()
                }
            )

            // Example 2: Standard with shadow
            BottomSheetContainer(
                maxHeight: 300,
                useGlassmorphic: false,
                background: {
                    LinearGradient(
                        colors: [
                            Color(red: 0.1, green: 0.1, blue: 0.15),
                            Color(red: 0.15, green: 0.15, blue: 0.2)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                },
                content: {
                    VStack {
                        Text("Standard Sheet")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        Text("With shadow effect")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding()
                }
            )
        }
    }
}
