import SwiftUI

/**
 * SharedTemplateView
 * Browse, preview, and import shared templates from team/public library
 */

struct SharedTemplateView: View {
    @SwiftUI.Environment(\.dismiss) private var dismiss
    @StateObject private var service = SharedTemplateService.shared
    @State private var searchQuery = ""
    @State private var selectedCategory: TemplateCategory?
    @State private var selectedShareType: ShareType?
    @State private var selectedTemplate: SharedTemplate?
    @State private var showPreview = false
    @State private var showImportSuccess = false
    @State private var importedTemplateName = ""

    var filteredTemplates: [SharedTemplate] {
        var templates = service.sharedTemplates

        // Apply search filter
        if !searchQuery.isEmpty {
            templates = service.searchSharedTemplates(query: searchQuery)
        }

        // Apply category filter
        if let category = selectedCategory {
            templates = templates.filter { $0.category == category }
        }

        // Apply share type filter
        if let shareType = selectedShareType {
            templates = templates.filter { $0.shareType == shareType }
        }

        return templates
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "1C1C1E")
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    headerView

                    // Search & Filters
                    searchAndFiltersView

                    // Template List
                    if service.isLoading {
                        loadingView
                    } else if filteredTemplates.isEmpty {
                        emptyStateView
                    } else {
                        templateListView
                    }
                }
            }
            .navigationBarHidden(true)
            .task {
                do {
                    try await service.fetchSharedTemplates(userId: "user-123") // TODO: Get from auth
                } catch {
                    Logger.error("Error loading shared templates: \(error)", category: .app)
                }
            }
            .sheet(isPresented: $showPreview) {
                if let template = selectedTemplate {
                    TemplatePreviewView(
                        template: template,
                        onImport: {
                            importTemplate(template)
                        }
                    )
                }
            }
            .overlay(
                importSuccessToast
            )
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Shared Templates")
                    .font(.title2.bold())
                    .foregroundColor(.white)

                Text("\(filteredTemplates.count) templates available")
                    .font(.caption)
                    .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
            }
        }
        .padding()
        .background(Color(hex: "2C2C2E"))
    }

    // MARK: - Search & Filters

    private var searchAndFiltersView: some View {
        VStack(spacing: 12) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white.opacity(DesignTokens.Opacity.overlayStrong))

                TextField("Search templates...", text: $searchQuery)
                    .foregroundColor(.white)
                    .autocapitalization(.none)

                if !searchQuery.isEmpty {
                    Button {
                        searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(DesignTokens.Opacity.overlayStrong))
                    }
                }
            }
            .padding()
            .background(Color.white.opacity(DesignTokens.Opacity.glassLight))
            .cornerRadius(DesignTokens.Radius.button)

            // Filter Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Share Type Filter
                    FilterPill(
                        title: "All",
                        isSelected: selectedShareType == nil,
                        action: { selectedShareType = nil }
                    )

                    FilterPill(
                        title: "Public",
                        icon: "globe",
                        isSelected: selectedShareType == .publicAccess,
                        action: { selectedShareType = .publicAccess }
                    )

                    FilterPill(
                        title: "Team",
                        icon: "person.3.fill",
                        isSelected: selectedShareType == .team,
                        action: { selectedShareType = .team }
                    )

                    Divider()
                        .frame(height: 24)
                        .background(Color.white.opacity(DesignTokens.Opacity.overlayMedium))

                    // Category Filters
                    ForEach([TemplateCategory.general, .followUp, .confirmation, .outOfOffice], id: \.self) { category in
                        FilterPill(
                            title: category.rawValue.capitalized,
                            isSelected: selectedCategory == category,
                            action: {
                                selectedCategory = selectedCategory == category ? nil : category
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .background(Color(hex: "2C2C2E"))
    }

    // MARK: - Template List

    private var templateListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(filteredTemplates) { template in
                    TemplateCardView(template: template) {
                        selectedTemplate = template
                        showPreview = true
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Loading & Empty States

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(.white)
                .scaleEffect(1.5)

            Text("Loading templates...")
                .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(DesignTokens.Opacity.overlayMedium))

            Text("No Templates Found")
                .font(.headline)
                .foregroundColor(.white)

            Text("Try adjusting your filters or search query")
                .font(.subheadline)
                .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Import Success Toast

    @ViewBuilder
    private var importSuccessToast: some View {
        if showImportSuccess {
            VStack {
                Spacer()

                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Template Imported!")
                            .font(.headline)
                            .foregroundColor(.white)

                        Text(importedTemplateName)
                            .font(.caption)
                            .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
                    }
                }
                .padding()
                .background(Color(hex: "2C2C2E"))
                .cornerRadius(DesignTokens.Radius.button)
                .shadow(radius: 10)
                .padding()
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.spring(), value: showImportSuccess)
        }
    }

    // MARK: - Actions

    private func importTemplate(_ template: SharedTemplate) {
        Task {
            do {
                let imported = try await service.importTemplate(template)

                await MainActor.run {
                    importedTemplateName = imported.name
                    showImportSuccess = true
                    showPreview = false

                    // Hide success message after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showImportSuccess = false
                    }

                    let impact = UINotificationFeedbackGenerator()
                    impact.notificationOccurred(.success)
                }
            } catch {
                Logger.error("Error importing template: \(error)", category: .app)
            }
        }
    }
}

// MARK: - Template Card View

struct TemplateCardView: View {
    let template: SharedTemplate
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(template.name)
                            .font(.headline)
                            .foregroundColor(.white)
                            .lineLimit(2)

                        Text("by \(template.authorName)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))
                    }

                    Spacer()

                    // Share Type Badge
                    shareTypeBadge
                }

                // Content Preview
                Text(template.content)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
                    .lineLimit(3)

                // Footer Stats
                HStack(spacing: 16) {
                    // Rating
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)

                        Text(template.formattedRating)
                            .font(.caption.bold())
                            .foregroundColor(.white)

                        Text("(\(template.ratingCount))")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(DesignTokens.Opacity.overlayStrong))
                    }

                    // Usage Count
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(.blue)
                            .font(.caption)

                        Text("\(template.usageCount)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
                    }

                    // Category
                    HStack(spacing: 4) {
                        Image(systemName: "tag.fill")
                            .foregroundColor(.purple)
                            .font(.caption)

                        Text(template.category.rawValue.capitalized)
                            .font(.caption)
                            .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
                    }

                    Spacer()

                    // Popular Badge
                    if template.isPopular {
                        HStack(spacing: 2) {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.orange)
                                .font(.caption2)
                            Text("Popular")
                                .font(.caption2.bold())
                                .foregroundColor(.orange)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(DesignTokens.Opacity.overlayLight))
                        .cornerRadius(DesignTokens.Radius.chip)
                    }
                }
            }
            .padding()
            .background(Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
            .cornerRadius(DesignTokens.Radius.button)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.white.opacity(DesignTokens.Opacity.glassLight), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    private var shareTypeBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: template.shareType == .publicAccess ? "globe" : "person.3.fill")
                .font(.caption2)

            Text(template.shareType.rawValue.capitalized)
                .font(.caption2.bold())
        }
        .foregroundColor(template.shareType == .publicAccess ? .blue : .green)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background((template.shareType == .publicAccess ? Color.blue : Color.green).opacity(DesignTokens.Opacity.overlayLight))
        .cornerRadius(DesignTokens.Radius.chip)
    }
}

// MARK: - Filter Pill

struct FilterPill: View {
    let title: String
    var icon: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }

                Text(title)
                    .font(.subheadline.bold())
            }
            .foregroundColor(isSelected ? .black : .white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.white : Color.white.opacity(DesignTokens.Opacity.glassLight))
            .cornerRadius(DesignTokens.Radius.modal)
        }
    }
}

// MARK: - Template Preview View

struct TemplatePreviewView: View {
    @SwiftUI.Environment(\.dismiss) private var dismiss
    let template: SharedTemplate
    let onImport: () -> Void

    @State private var selectedRating: Int = 0
    @State private var hasRated = false

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "1C1C1E")
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text(template.name)
                                .font(.title2.bold())
                                .foregroundColor(.white)

                            HStack {
                                Text("by \(template.authorName)")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))

                                Spacer()

                                // Share Type Badge
                                HStack(spacing: 4) {
                                    Image(systemName: template.shareType == .publicAccess ? "globe" : "person.3.fill")
                                        .font(.caption)

                                    Text(template.shareType.rawValue.capitalized)
                                        .font(.caption.bold())
                                }
                                .foregroundColor(template.shareType == .publicAccess ? .blue : .green)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background((template.shareType == .publicAccess ? Color.blue : Color.green).opacity(DesignTokens.Opacity.overlayLight))
                                .cornerRadius(DesignTokens.Radius.chip)
                            }
                        }

                        Divider()
                            .background(Color.white.opacity(DesignTokens.Opacity.overlayMedium))

                        // Stats Row
                        HStack(spacing: 24) {
                            StatItem(
                                icon: "star.fill",
                                color: .yellow,
                                title: "Rating",
                                value: "\(template.formattedRating) (\(template.ratingCount))"
                            )

                            StatItem(
                                icon: "person.2.fill",
                                color: .blue,
                                title: "Uses",
                                value: "\(template.usageCount)"
                            )

                            StatItem(
                                icon: "tag.fill",
                                color: .purple,
                                title: "Category",
                                value: template.category.rawValue.capitalized
                            )
                        }

                        Divider()
                            .background(Color.white.opacity(DesignTokens.Opacity.overlayMedium))

                        // Content
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Template Content")
                                .font(.headline)
                                .foregroundColor(.white)

                            Text(template.content)
                                .font(.body)
                                .foregroundColor(.white.opacity(DesignTokens.Opacity.textSecondary))
                                .padding()
                                .background(Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
                                .cornerRadius(DesignTokens.Radius.button)
                        }

                        // Rating Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Rate This Template")
                                .font(.headline)
                                .foregroundColor(.white)

                            if hasRated {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Thanks for rating!")
                                        .foregroundColor(.green)
                                }
                            } else {
                                HStack(spacing: 12) {
                                    ForEach(1...5, id: \.self) { star in
                                        Button {
                                            selectedRating = star
                                            rateTemplate(star)
                                        } label: {
                                            Image(systemName: star <= selectedRating ? "star.fill" : "star")
                                                .font(.title2)
                                                .foregroundColor(star <= selectedRating ? .yellow : .white.opacity(DesignTokens.Opacity.overlayMedium))
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
                        .cornerRadius(DesignTokens.Radius.button)

                        // Import Button
                        Button {
                            onImport()
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.down.fill")
                                Text("Import to My Templates")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(DesignTokens.Radius.button)
                        }
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
                    }
                }
            }
        }
    }

    private func rateTemplate(_ rating: Int) {
        Task {
            do {
                try await SharedTemplateService.shared.rateTemplate(template.id, rating: rating)

                await MainActor.run {
                    hasRated = true

                    let impact = UINotificationFeedbackGenerator()
                    impact.notificationOccurred(.success)
                }
            } catch {
                Logger.error("Error rating template: \(error)", category: .app)
            }
        }
    }
}

// MARK: - Stat Item

struct StatItem: View {
    let icon: String
    let color: Color
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)

            VStack(spacing: 2) {
                Text(value)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)

                Text(title)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

struct SharedTemplateView_Previews: PreviewProvider {
    static var previews: some View {
        SharedTemplateView()
    }
}
