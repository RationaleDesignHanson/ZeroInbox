import SwiftUI
import SafariServices

/// Safari view wrapper for sheet presentation (uses callback instead of binding)
struct SafariViewWrapper: UIViewControllerRepresentable {
    let url: URL
    let onDismiss: () -> Void

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        config.barCollapsingEnabled = true

        let safari = SFSafariViewController(url: url, configuration: config)
        safari.delegate = context.coordinator
        safari.dismissButtonStyle = .done
        safari.preferredControlTintColor = .systemPurple

        return safari
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // No updates needed
    }

    func makeCoordinator() -> SafariWrapperCoordinator {
        SafariWrapperCoordinator(onDismiss: onDismiss)
    }

    class SafariWrapperCoordinator: NSObject, SFSafariViewControllerDelegate {
        let onDismiss: () -> Void

        init(onDismiss: @escaping () -> Void) {
            self.onDismiss = onDismiss
        }

        func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
            // User tapped done button
            Logger.info("Safari view dismissed by user", category: .modal)
            onDismiss()
        }
    }
}
