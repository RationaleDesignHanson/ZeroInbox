import SwiftUI

/// Bottom sheet showing labeled action buttons
/// Appears when user taps the menu button in bottom nav
struct ActionsBottomSheet: View {
    @Binding var showSettings: Bool
    @Binding var showSplayView: Bool
    @Binding var showSearch: Bool
    @Binding var showSavedMail: Bool
    let onRefresh: (() async -> Void)?
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            SheetHandleBar(cornerRadius: 2.5, verticalPadding: 12)

            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.bottom, 20)

            VStack(spacing: 16) {
                actionRow(icon: "gearshape.fill", title: "Settings") {
                    showSettings = true
                    dismiss()
                }

                actionRow(icon: "rectangle.grid.1x2", title: "View Stacks") {
                    showSplayView = true
                    dismiss()
                }

                actionRow(icon: "magnifyingglass", title: "Search") {
                    showSearch = true
                    dismiss()
                }

                actionRow(icon: "folder.fill", title: "Saved Mail") {
                    showSavedMail = true
                    dismiss()
                }

                actionRow(icon: "arrow.clockwise", title: "Refresh") {
                    Task {
                        await onRefresh?()
                    }
                    dismiss()
                }
            }
            .padding(.bottom, 40)
        }
        .padding(.horizontal, 24)
        .presentationDetents([.height(380)])
        .presentationDragIndicator(.hidden)
    }

    @ViewBuilder
    private func actionRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.white.opacity(DesignTokens.Opacity.textTertiary))
                    .frame(width: 32)

                Text(title)
                    .font(.body)
                    .foregroundColor(.white)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(DesignTokens.Opacity.overlayStrong))
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
            .cornerRadius(DesignTokens.Radius.button)
        }
    }
}

// MARK: - Preview
#if DEBUG
struct ActionsBottomSheet_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            LinearGradient(
                colors: [.blue, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ActionsBottomSheet(
                showSettings: .constant(false),
                showSplayView: .constant(false),
                showSearch: .constant(false),
                showSavedMail: .constant(false),
                onRefresh: {
                    print("Refresh triggered")
                }
            )
        }
    }
}
#endif
