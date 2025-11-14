import SwiftUI

/// Top navigation bar with archetype name and pull-to-refresh
/// Redesigned for 1.8.0 - archetype name moved to top
struct TopNavigationBar: View {
    @ObservedObject var viewModel: EmailViewModel
    let onRefresh: () async -> Void

    @State private var isRefreshing = false

    var body: some View {
        VStack(spacing: 0) {
            // Pull-to-refresh indicator (shows when refreshing)
            if isRefreshing {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.white)
                    Text("Refreshing...")
                        .font(.caption)
                        .foregroundColor(.white.opacity(DesignTokens.Opacity.textTertiary))
                }
                .padding(.top, 50)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .zIndex(100)
    }

    /// Trigger refresh animation and call refresh handler
    private func triggerRefresh() {
        guard !isRefreshing else { return }

        isRefreshing = true
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        Logger.info("Pull-to-refresh triggered", category: .app)

        Task {
            await onRefresh()

            // Wait a moment to show completion
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

            await MainActor.run {
                withAnimation {
                    isRefreshing = false
                }
            }
        }
    }
}

// MARK: - Preview
#if DEBUG
struct TopNavigationBar_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            LinearGradient(
                colors: [.blue, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            TopNavigationBar(
                viewModel: EmailViewModel(
                    userPreferences: UserPreferencesService(),
                    appState: AppStateManager(),
                    cardManagement: CardManagementService()
                ),
                onRefresh: {
                    print("Refresh triggered")
                }
            )
        }
    }
}
#endif

