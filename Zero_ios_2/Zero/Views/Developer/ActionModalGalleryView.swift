import SwiftUI

/// Developer/QA tool for testing all action modals in isolation
/// Access: Settings → Developer Tools → Action Modal Gallery (DEBUG builds only)
struct ActionModalGalleryView: View {
    @EnvironmentObject var services: ServiceContainer
    @StateObject private var viewModel = ActionModalGalleryViewModel()
    @Environment(\.dismiss) private var dismiss

    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.1, green: 0.1, blue: 0.3),
                Color(red: 0.2, green: 0.1, blue: 0.4)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient

                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        headerSection

                        // Filter controls
                        filterSection

                        // Stats
                        statsSection

                        // Action list
                        actionsList
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("Action Modal Gallery")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
        }
        // Disabled - ActionRegistry not in ServiceContainer yet
        // .onAppear {
        //     viewModel.loadActions(from: services.actionRegistry)
        // }
        // .sheet(item: $viewModel.selectedAction) { action in
        //     ActionModalTestView(action: action, services: services)
        // }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.stack.3d.up.fill")
                .font(.system(size: 50))
                .foregroundColor(.cyan)

            Text("Action Modal Gallery")
                .font(.title2.bold())
                .foregroundColor(.white)

            Text("Test all IN_APP action modals with mock data")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
        .padding(.horizontal)
    }

    // MARK: - Filter Section

    private var filterSection: some View {
        VStack(spacing: 16) {
            // Mode filter
            HStack(spacing: 12) {
                Text("Mode:")
                    .font(.subheadline.bold())
                    .foregroundColor(.white.opacity(0.7))

                ForEach(ActionModeFilter.allCases, id: \.self) { mode in
                    FilterChip(
                        title: mode.displayName,
                        icon: mode.icon,
                        isSelected: viewModel.modeFilter == mode
                    ) {
                        viewModel.modeFilter = mode
                    }
                }

                Spacer()
            }

            // Permission filter
            HStack(spacing: 12) {
                Text("Access:")
                    .font(.subheadline.bold())
                    .foregroundColor(.white.opacity(0.7))

                ForEach(ActionPermissionFilter.allCases, id: \.self) { permission in
                    FilterChip(
                        title: permission.displayName,
                        icon: permission.icon,
                        isSelected: viewModel.permissionFilter == permission
                    ) {
                        viewModel.permissionFilter = permission
                    }
                }

                Spacer()
            }

            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white.opacity(0.5))

                TextField("Search actions...", text: $viewModel.searchText)
                    .foregroundColor(.white)
                    .textFieldStyle(.plain)

                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
            .padding(12)
            .background(Color.white.opacity(0.1))
            .cornerRadius(10)
        }
        .padding(.horizontal)
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        HStack(spacing: 16) {
            StatCard(
                title: "Total",
                value: "\(viewModel.totalActionsCount)",
                icon: "square.stack.3d.up",
                color: .cyan
            )

            StatCard(
                title: "Showing",
                value: "\(viewModel.filteredActions.count)",
                icon: "eye",
                color: .blue
            )

            StatCard(
                title: "Premium",
                value: "\(viewModel.premiumActionsCount)",
                icon: "star.fill",
                color: .yellow
            )
        }
        .padding(.horizontal)
    }

    // MARK: - Actions List

    private var actionsList: some View {
        LazyVStack(spacing: 12) {
            if viewModel.filteredActions.isEmpty {
                emptyStateView
            } else {
                ForEach(viewModel.filteredActions) { action in
                    ActionCard(action: action) {
                        viewModel.selectedAction = action
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))

            Text("No actions found")
                .font(.headline)
                .foregroundColor(.white.opacity(0.6))

            Text("Try adjusting your filters")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Supporting Types

enum ActionModeFilter: CaseIterable {
    case all, mail, ads, both

    var displayName: String {
        switch self {
        case .all: return "All"
        case .mail: return "Mail"
        case .ads: return "Ads"
        case .both: return "Both"
        }
    }

    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .mail: return "envelope"
        case .ads: return "megaphone"
        case .both: return "arrow.left.arrow.right"
        }
    }
}

enum ActionPermissionFilter: CaseIterable {
    case all, free, premium

    var displayName: String {
        switch self {
        case .all: return "All"
        case .free: return "Free"
        case .premium: return "Premium"
        }
    }

    var icon: String {
        switch self {
        case .all: return "checkmark.circle"
        case .free: return "person"
        case .premium: return "star"
        }
    }
}

// MARK: - View Components

struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption.bold())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.cyan : Color.white.opacity(0.1))
            .foregroundColor(isSelected ? .black : .white)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title.bold())
                .foregroundColor(.white)

            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

struct ActionCard: View {
    let action: TestableAction
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(action.color.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: action.icon)
                        .foregroundColor(action.color)
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(action.displayName)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)

                    HStack(spacing: 8) {
                        // Mode badge
                        Badge(text: action.mode.rawValue.uppercased(), color: .blue)

                        // Priority badge
                        Badge(text: "P\(action.priority.rawValue)", color: priorityColor(action.priority))

                        // Premium badge
                        if action.isPremium {
                            Badge(text: "PREMIUM", color: .yellow)
                        }

                        // JSON badge
                        if action.hasJSONConfig {
                            Badge(text: "JSON", color: .green)
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(16)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    private func priorityColor(_ priority: ActionPriority) -> Color {
        switch priority {
        case .critical, .veryHigh: return .red
        case .high, .mediumHigh: return .orange
        case .medium, .mediumLow: return .blue
        case .low, .veryLow: return .gray
        }
    }
}

struct Badge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .cornerRadius(4)
    }
}

// MARK: - Preview

#if DEBUG
struct ActionModalGalleryView_Previews: PreviewProvider {
    static var previews: some View {
        ActionModalGalleryView()
            .environmentObject(ServiceContainer())
    }
}
#endif
