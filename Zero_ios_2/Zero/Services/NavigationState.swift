import SwiftUI

/// Shared state for bottom navigation expansion and card stack scaling
/// Used to coordinate between BottomNavigationBar, CardStackView, and ContentView
class NavigationState: ObservableObject {
    /// Whether the quick actions row is expanded (via swipe up or tap chevron)
    @Published var actionsExpanded: Bool = false

    /// Whether the actions bottom sheet is presented (via tap menu button)
    @Published var sheetPresented: Bool = false

    /// Toggle actions expansion with animation
    func toggleActions() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            actionsExpanded.toggle()
        }
    }

    /// Collapse actions (called when user selects an action or dismisses)
    func collapseActions() {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
            actionsExpanded = false
        }
    }

    /// Show bottom sheet
    func showSheet() {
        sheetPresented = true
    }

    /// Dismiss bottom sheet
    func dismissSheet() {
        sheetPresented = false
    }
}
