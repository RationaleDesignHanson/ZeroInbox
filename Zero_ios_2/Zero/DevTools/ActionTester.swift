import SwiftUI

// ActionTester - Temporarily Disabled
// This debug tool needs updates to work with the current codebase structure.
// The file will be re-enabled once the following issues are resolved:
// - ActionRegistry.allActions is private (needs public accessor)
// - ActionConfig doesn't have reachScore property
// - EmailCard initializer signature has changed
// - EmailAction initializer parameter order has changed

#if DEBUG
struct ActionTester_Disabled: View {
    var body: some View {
        VStack {
            Text("Action Tester")
                .font(.title)
            Text("Temporarily disabled - needs updates")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
#endif
