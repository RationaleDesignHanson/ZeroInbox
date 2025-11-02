import SwiftUI
import SafariServices

/// Enhanced Safari view wrapper with custom context header
/// Shows action name and email context so users don't lose track while browsing
struct SafariViewWithContext: UIViewControllerRepresentable {
    let url: URL
    let actionName: String?
    let cardTitle: String?
    let cardType: CardType?
    let onDismiss: () -> Void

    func makeUIViewController(context: Context) -> SafariWrapperViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        config.barCollapsingEnabled = true

        let safari = SFSafariViewController(url: url, configuration: config)
        safari.delegate = context.coordinator
        safari.dismissButtonStyle = .done
        safari.preferredControlTintColor = .systemPurple

        let wrapper = SafariWrapperViewController()
        wrapper.safariViewController = safari
        wrapper.actionName = actionName
        wrapper.cardTitle = cardTitle
        wrapper.cardType = cardType

        return wrapper
    }

    func updateUIViewController(_ uiViewController: SafariWrapperViewController, context: Context) {
        // No updates needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onDismiss: onDismiss)
    }

    class Coordinator: NSObject, SFSafariViewControllerDelegate {
        let onDismiss: () -> Void

        init(onDismiss: @escaping () -> Void) {
            self.onDismiss = onDismiss
        }

        func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
            Logger.info("Safari view dismissed by user", category: .modal)
            onDismiss()
        }
    }
}

/// Container view controller that wraps Safari with a custom header
class SafariWrapperViewController: UIViewController {
    var safariViewController: SFSafariViewController?
    var actionName: String?
    var cardTitle: String?
    var cardType: CardType?

    private var contextHeaderView: UIView?
    private let headerHeight: CGFloat = 60

    override func viewDidLoad() {
        super.viewDidLoad()

        setupContextHeader()
        setupSafariView()
    }

    private func setupContextHeader() {
        guard let actionName = actionName else { return }

        // Create header container with glassmorphic background
        let headerView = UIView()
        headerView.translatesAutoresizingMaskIntoConstraints = false

        // Blur effect for glassmorphism
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(blurView)

        // Action icon
        let iconLabel = UILabel()
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        iconLabel.text = getIconForAction(actionName)
        iconLabel.font = .systemFont(ofSize: 20)

        // Action name label
        let actionLabel = UILabel()
        actionLabel.translatesAutoresizingMaskIntoConstraints = false
        actionLabel.text = actionName
        actionLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        actionLabel.textColor = .white
        actionLabel.numberOfLines = 1
        actionLabel.lineBreakMode = .byTruncatingTail
        actionLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        // Separator bullet
        let separatorLabel = UILabel()
        separatorLabel.translatesAutoresizingMaskIntoConstraints = false
        separatorLabel.text = "•"
        separatorLabel.font = .systemFont(ofSize: 15, weight: .medium)
        separatorLabel.textColor = .white.withAlphaComponent(0.5)

        // Card title label (context)
        let contextLabel = UILabel()
        contextLabel.translatesAutoresizingMaskIntoConstraints = false
        contextLabel.text = cardTitle ?? "Loading..."
        contextLabel.font = .systemFont(ofSize: 15, weight: .regular)
        contextLabel.textColor = .white.withAlphaComponent(0.7)
        contextLabel.numberOfLines = 1
        contextLabel.lineBreakMode = .byTruncatingTail

        // Single horizontal stack with all elements
        let mainStack = UIStackView(arrangedSubviews: [iconLabel, actionLabel, separatorLabel, contextLabel])
        mainStack.axis = .horizontal
        mainStack.spacing = 8
        mainStack.alignment = .center
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        headerView.addSubview(mainStack)
        view.addSubview(headerView)

        // Add bottom border
        let borderView = UIView()
        borderView.translatesAutoresizingMaskIntoConstraints = false
        borderView.backgroundColor = .white.withAlphaComponent(0.2)
        headerView.addSubview(borderView)

        contextHeaderView = headerView

        // Constraints
        NSLayoutConstraint.activate([
            // Blur view fills header
            blurView.topAnchor.constraint(equalTo: headerView.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),

            // Header at top of screen
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: headerHeight),

            // Content stack centered in header
            mainStack.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            mainStack.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            mainStack.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),

            // Border at bottom
            borderView.heightAnchor.constraint(equalToConstant: 1),
            borderView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            borderView.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            borderView.bottomAnchor.constraint(equalTo: headerView.bottomAnchor)
        ])
    }

    private func setupSafariView() {
        guard let safariVC = safariViewController else { return }

        // Add Safari as child view controller
        addChild(safariVC)
        view.addSubview(safariVC.view)
        safariVC.didMove(toParent: self)

        // Position Safari below header (or full screen if no header)
        safariVC.view.translatesAutoresizingMaskIntoConstraints = false

        if contextHeaderView != nil {
            NSLayoutConstraint.activate([
                safariVC.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: headerHeight),
                safariVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                safariVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                safariVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        } else {
            // No header, full screen Safari
            NSLayoutConstraint.activate([
                safariVC.view.topAnchor.constraint(equalTo: view.topAnchor),
                safariVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                safariVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                safariVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }
    }

    /// Get emoji icon for action type
    private func getIconForAction(_ action: String) -> String {
        let lowercasedAction = action.lowercased()

        // Education/School
        if lowercasedAction.contains("grade") || lowercasedAction.contains("assignment") {
            return "📊"
        }
        if lowercasedAction.contains("homework") || lowercasedAction.contains("study") {
            return "📝"
        }

        // Shopping
        if lowercasedAction.contains("shop") || lowercasedAction.contains("browse") || lowercasedAction.contains("deal") {
            return "🛍️"
        }
        if lowercasedAction.contains("track") || lowercasedAction.contains("package") || lowercasedAction.contains("delivery") {
            return "📦"
        }
        if lowercasedAction.contains("pay") || lowercasedAction.contains("invoice") || lowercasedAction.contains("bill") {
            return "💳"
        }

        // Travel
        if lowercasedAction.contains("flight") || lowercasedAction.contains("check in") || lowercasedAction.contains("boarding") {
            return "✈️"
        }
        if lowercasedAction.contains("hotel") || lowercasedAction.contains("reservation") || lowercasedAction.contains("booking") {
            return "🏨"
        }

        // Work/Business
        if lowercasedAction.contains("meeting") || lowercasedAction.contains("schedule") || lowercasedAction.contains("demo") {
            return "📅"
        }
        if lowercasedAction.contains("document") || lowercasedAction.contains("review") || lowercasedAction.contains("approve") {
            return "📄"
        }
        if lowercasedAction.contains("spreadsheet") || lowercasedAction.contains("report") {
            return "📊"
        }

        // Healthcare/Appointments
        if lowercasedAction.contains("appointment") || lowercasedAction.contains("doctor") || lowercasedAction.contains("prescription") {
            return "🏥"
        }

        // Food/Restaurants
        if lowercasedAction.contains("restaurant") || lowercasedAction.contains("menu") || lowercasedAction.contains("order food") {
            return "🍽️"
        }

        // Security/Account
        if lowercasedAction.contains("security") || lowercasedAction.contains("verify") || lowercasedAction.contains("password") {
            return "🔒"
        }

        // Social/Events
        if lowercasedAction.contains("event") || lowercasedAction.contains("rsvp") || lowercasedAction.contains("invitation") {
            return "🎉"
        }

        // Generic link/browser
        return "🔗"
    }
}
