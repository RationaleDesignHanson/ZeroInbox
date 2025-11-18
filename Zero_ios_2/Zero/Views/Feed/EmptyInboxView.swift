import SwiftUI

/// Empty state view shown when there are no cards to display
struct EmptyInboxView: View {
    var body: some View {
        GenericEmptyState(
            icon: "tray",
            title: "All Caught Up!",
            message: "No more emails to review"
        )
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
