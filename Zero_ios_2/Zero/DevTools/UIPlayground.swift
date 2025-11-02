#if DEBUG
import SwiftUI

/// DEBUG-ONLY: Interactive UI component gallery for development
/// Shows all major UI components with annotations
/// Never included in Release builds

struct UIPlayground: View {
    @StateObject private var annotationState = AnnotationState.shared
    @State private var selectedCategory: Category = .all

    enum Category: String, CaseIterable {
        case all = "All Components"
        case cards = "Cards"
        case navigation = "Navigation"
        case buttons = "Buttons & Controls"
        case modals = "Modals"
        case overlays = "Overlays & Indicators"

        var icon: String {
            switch self {
            case .all: return "square.grid.2x2"
            case .cards: return "rectangle.portrait"
            case .navigation: return "arrow.left.arrow.right"
            case .buttons: return "hand.tap"
            case .modals: return "square.on.square"
            case .overlays: return "tag"
            }
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 40) {
                    // Header with annotation toggle
                    VStack(spacing: 16) {
                        Text("UI Component Gallery")
                            .font(.largeTitle.bold())
                            .foregroundColor(.white)

                        Text("Development Preview System")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))

                        AnnotationToggle()
                    }
                    .padding(.top, 20)

                    // Category filter
                    categoryPicker

                    Divider()
                        .background(Color.white.opacity(0.3))

                    // Component sections
                    if selectedCategory == .all || selectedCategory == .cards {
                        cardsSection
                    }

                    if selectedCategory == .all || selectedCategory == .navigation {
                        navigationSection
                    }

                    if selectedCategory == .all || selectedCategory == .buttons {
                        buttonsSection
                    }

                    if selectedCategory == .all || selectedCategory == .modals {
                        modalsSection
                    }

                    if selectedCategory == .all || selectedCategory == .overlays {
                        overlaysSection
                    }
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [.purple, .blue],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
        }
    }

    // MARK: - Category Picker

    var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Category.allCases, id: \.self) { category in
                    Button {
                        withAnimation {
                            selectedCategory = category
                        }
                        HapticService.shared.lightImpact()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: category.icon)
                            Text(category.rawValue)
                        }
                        .font(.subheadline.weight(selectedCategory == category ? .bold : .regular))
                        .foregroundColor(selectedCategory == category ? .white : .white.opacity(0.7))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(selectedCategory == category ? Color.white.opacity(0.3) : Color.clear)
                                .overlay(
                                    Capsule()
                                        .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                }
            }
        }
    }

    // MARK: - Cards Section

    var cardsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionHeader("Email Cards", icon: "rectangle.portrait")

            // Simple Card (mock data)
            let mockCard = PreviewHelpers.mockEmailCard(
                type: .mail,
                title: "Field Trip Permission Form",
                sender: "Mrs. Johnson",
                summary: "Please sign the attached permission form..."
            )

            SimpleCardView(
                card: mockCard,
                isTopCard: true,
                viewModel: PreviewHelpers.mockEmailViewModel(),
                cardIndex: 0
            )
            .annotated("Card_Container", type: .layout)
            .frame(height: 480)
            .scaleEffect(0.85)  // Scale down for gallery view

            // Card components preview
            VStack(alignment: .leading, spacing: 16) {
                Text("Card Components:")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))

                // Card header
                HStack(spacing: 16) {
                    // View button
                    VStack(spacing: 4) {
                        Image(systemName: "envelope.open.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.7))
                        Text("View")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.85))
                    }
                    .frame(width: 56, height: 56)
                    .background(Color.white.opacity(0.25))
                    .cornerRadius(DesignTokens.Radius.button)
                    .annotated("Card_ViewButton", type: .interactive)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Mrs. Johnson")
                            .font(.headline)
                            .foregroundColor(.white)
                            .annotated("Card_SenderName", type: .text)

                        Text("2 hours ago")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .annotated("Card_TimeAgo", type: .text)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)

                // Action button
                HStack(spacing: 8) {
                    Text(">>>")
                        .font(.system(size: 16, weight: .bold))
                    Text("Sign & Send")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.15))
                )
                .annotated("Card_ActionButton", type: .interactive)
            }
            .padding()
            .background(Color.black.opacity(0.2))
            .cornerRadius(16)
        }
    }

    // MARK: - Navigation Section

    var navigationSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionHeader("Navigation Bars", icon: "arrow.left.arrow.right")

            // Bottom Navigation
            VStack(spacing: 16) {
                Text("Bottom Navigation:")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))

                // Mail/Ads toggle
                HStack(spacing: 6) {
                    Text("Mail")
                        .font(.headline.bold())
                        .foregroundColor(.white)
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.15))
                .cornerRadius(DesignTokens.Radius.chip)
                .annotated("BottomNav_ArchetypeToggle", type: .interactive)

                // Email count
                HStack(spacing: 6) {
                    Image(systemName: "envelope.fill")
                        .font(.caption)
                        .foregroundColor(.blue.opacity(0.8))
                        .annotated("BottomNav_EmailIcon", type: .status)
                    Text("12")
                        .font(.headline.bold())
                        .foregroundColor(.white)
                        .annotated("BottomNav_EmailCount", type: .text)
                    Text("left")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                        .annotated("BottomNav_EmailLabel", type: .text)
                }

                // Stacks button
                HStack(spacing: 4) {
                    Image(systemName: "rectangle.grid.1x2")
                        .font(.caption)
                        .foregroundColor(.purple.opacity(0.8))
                    Text("Stacks")
                        .font(.caption.bold())
                        .foregroundColor(.white.opacity(0.7))
                }
                .annotated("BottomNav_StacksButton", type: .interactive)

                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 3)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .green],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * 0.6, height: 3)
                    }
                }
                .frame(height: 3)
                .annotated("BottomNav_ProgressBar", type: .status)
            }
            .padding()
            .background(Color.black.opacity(0.2))
            .cornerRadius(16)
        }
    }

    // MARK: - Buttons Section

    var buttonsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionHeader("Buttons & Controls", icon: "hand.tap")

            VStack(spacing: 16) {
                // Primary button
                StandardButton(title: "Primary Action", style: .primary) {}
                    .annotated("Button_Primary", type: .interactive)

                // Secondary button
                StandardButton(title: "Secondary Action", style: .secondary) {}
                    .annotated("Button_Secondary", type: .interactive)

                // Destructive button
                StandardButton(title: "Delete", style: .destructive) {}
                    .annotated("Button_Destructive", type: .interactive)

                // Icon button
                Button {
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(0.3))
                        )
                }
                .annotated("Button_Icon_Settings", type: .interactive)
            }
            .padding()
            .background(Color.black.opacity(0.2))
            .cornerRadius(16)
        }
    }

    // MARK: - Modals Section

    var modalsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionHeader("Modal Components", icon: "square.on.square")

            VStack(spacing: 16) {
                Text("Modal elements are shown in their respective action flows")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)

                // Modal header example
                VStack(spacing: 12) {
                    Text("Modal Title")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .annotated("Modal_Title", type: .text)

                    Text("Modal description or instructions go here")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .annotated("Modal_Description", type: .text)
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(16)
            }
            .padding()
            .background(Color.black.opacity(0.2))
            .cornerRadius(16)
        }
    }

    // MARK: - Overlays Section

    var overlaysSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionHeader("Overlays & Indicators", icon: "tag")

            VStack(spacing: 16) {
                // Status badges
                HStack(spacing: 12) {
                    ForEach(["VIP", "URGENT", "LOW"], id: \.self) { badge in
                        Text(badge)
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                badge == "VIP" ? Color.blue.opacity(0.9) :
                                badge == "URGENT" ? Color.red.opacity(0.9) :
                                Color.green.opacity(0.9)
                            )
                            .cornerRadius(4)
                            .annotated("Badge_\(badge)", type: .status)
                    }
                }

                // Status dots
                HStack(spacing: 12) {
                    ForEach([
                        ("VIP", Color(red: 1.0, green: 0.84, blue: 0)),
                        ("Deadline", Color.orange),
                        ("Newsletter", Color.blue),
                        ("Shopping", Color.purple)
                    ], id: \.0) { label, color in
                        VStack(spacing: 4) {
                            Circle()
                                .fill(color)
                                .frame(width: 8, height: 8)
                                .annotated("StatusDot_\(label)", type: .status)
                            Text(label)
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
            }
            .padding()
            .background(Color.black.opacity(0.2))
            .cornerRadius(16)
        }
    }

    // MARK: - Helper Views

    func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
            Text(title)
                .font(.title2.bold())
        }
        .foregroundColor(.white)
    }
}

// MARK: - Preview Helpers

struct PreviewHelpers {
    static func mockEmailCard(
        type: CardType = .mail,
        title: String = "Sample Email",
        sender: String = "John Doe",
        summary: String = "This is a sample email summary..."
    ) -> EmailCard {
        EmailCard(
            id: UUID().uuidString,
            type: type,
            title: title,
            summary: summary,
            sender: EmailCard.Sender(name: sender, email: "\(sender.lowercased().replacingOccurrences(of: " ", with: "."))@example.com"),
            timeAgo: "2 hours ago",
            priority: .medium,
            hpa: "view_details"
        )
    }

    static func mockEmailViewModel() -> EmailViewModel {
        EmailViewModel(
            userPreferences: UserPreferencesService(),
            appState: AppStateManager(),
            cardManagement: CardManagementService()
        )
    }
}

// MARK: - Preview

#Preview {
    UIPlayground()
}

#endif
