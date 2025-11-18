import SwiftUI

/// Reusable drag handle bar for bottom sheets
/// Eliminates ~15 lines of duplicate code per bottom sheet
struct SheetHandleBar: View {
    var cornerRadius: CGFloat = 3
    var topPadding: CGFloat = 12
    var bottomPadding: CGFloat = 20

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.white.opacity(DesignTokens.Opacity.overlayMedium))
            .frame(width: 40, height: 5)
            .padding(.top, topPadding)
            .padding(.bottom, bottomPadding)
    }
}

/// Convenience initializer for symmetric vertical padding
extension SheetHandleBar {
    init(cornerRadius: CGFloat = 3, verticalPadding: CGFloat) {
        self.cornerRadius = cornerRadius
        self.topPadding = verticalPadding
        self.bottomPadding = verticalPadding
    }
}
