import SwiftUI

// UIPlayground - Temporarily Disabled
// This debug tool needs updates to work with the current codebase structure.

#if DEBUG
struct UIPlayground_Disabled: View {
    var body: some View {
        VStack {
            Text("UI Playground")
                .font(.title)
            Text("Temporarily disabled - needs updates")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
#endif
