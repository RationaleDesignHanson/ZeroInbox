import SwiftUI

struct TemplatePickerView: View {
    @ObservedObject var templateManager = TemplateManager.shared
    @Binding var isPresented: Bool
    @State private var searchQuery: String = ""
    @State private var selectedCategory: TemplateCategory? = nil
    @State private var showNewTemplateSheet = false
    @State private var showSharedTemplatesSheet = false

    let onSelectTemplate: (ReplyTemplate) -> Void

    var filteredTemplates: [ReplyTemplate] {
        var templates = templateManager.templates

        // Filter by search query
        if !searchQuery.isEmpty {
            templates = templateManager.searchTemplates(query: searchQuery)
        }

        // Filter by category
        if let category = selectedCategory {
            templates = templates.filter { $0.category == category }
        }

        return templates
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))

                    TextField("Search templates...", text: $searchQuery)
                        .textFieldStyle(.plain)
                        .foregroundColor(.white)

                    if !searchQuery.isEmpty {
                        Button(action: { searchQuery = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))
                        }
                    }
                }
                .padding()
                .background(Color.white.opacity(DesignTokens.Opacity.glassLight))
                .cornerRadius(DesignTokens.Radius.button)
                .padding()

                // Category filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        CategoryFilterButton(
                            category: nil,
                            isSelected: selectedCategory == nil,
                            onTap: { selectedCategory = nil }
                        )

                        ForEach(TemplateCategory.allCases, id: \.self) { category in
                            CategoryFilterButton(
                                category: category,
                                isSelected: selectedCategory == category,
                                onTap: { selectedCategory = category }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 12)

                // Browse Shared Templates Button
                Button {
                    showSharedTemplatesSheet = true
                } label: {
                    HStack {
                        Image(systemName: "globe")
                            .font(.subheadline)

                        Text("Browse Shared Templates")
                            .font(.subheadline.bold())

                        Spacer()

                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                    .padding()
                    .background(Color.blue.opacity(DesignTokens.Opacity.glassLight))
                    .cornerRadius(DesignTokens.Radius.button)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.blue.opacity(DesignTokens.Opacity.overlayMedium), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal)
                .padding(.bottom, 12)

                // Templates list
                if filteredTemplates.isEmpty {
                    Spacer()
                    GenericEmptyState(
                        icon: "text.bubble",
                        title: "No templates found",
                        message: "Create your first template to get started",
                        action: searchQuery.isEmpty && selectedCategory == nil ? ("Create Your First Template", { showNewTemplateSheet = true }) : nil
                    )
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredTemplates) { template in
                                TemplateRow(template: template) {
                                    templateManager.recordUsage(for: template)
                                    onSelectTemplate(template)
                                    isPresented = false
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.2),
                        Color(red: 0.05, green: 0.05, blue: 0.15)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        isPresented = false
                    }
                    .foregroundColor(.white)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showNewTemplateSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showNewTemplateSheet) {
                CreateTemplateView(isPresented: $showNewTemplateSheet)
            }
            .sheet(isPresented: $showSharedTemplatesSheet) {
                SharedTemplateView()
            }
        }
    }
}

struct CategoryFilterButton: View {
    let category: TemplateCategory?
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                if let category = category {
                    Image(systemName: category.icon)
                        .font(.caption)
                    Text(category.rawValue)
                        .font(.subheadline.bold())
                } else {
                    Text("All")
                        .font(.subheadline.bold())
                }
            }
            .foregroundColor(isSelected ? .white : .white.opacity(DesignTokens.Opacity.textDisabled))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color.white.opacity(DesignTokens.Opacity.glassLight))
            .cornerRadius(DesignTokens.Radius.modal)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TemplateRow: View {
    let template: ReplyTemplate
    let onTap: () -> Void
    @State private var showShareSheet = false

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Header
                HStack {
                    Image(systemName: template.category.icon)
                        .font(.caption)
                        .foregroundColor(.blue)

                    Text(template.name)
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()

                    if template.isBuiltIn {
                        Text("Built-in")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white.opacity(DesignTokens.Opacity.overlayStrong))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.white.opacity(DesignTokens.Opacity.glassLight))
                            .cornerRadius(DesignTokens.Radius.minimal)
                    }

                    if template.usageCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 10))
                            Text("\(template.usageCount)")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(.white.opacity(DesignTokens.Opacity.overlayStrong))
                    }

                    // Share button for user templates
                    if !template.isBuiltIn {
                        Button {
                            showShareSheet = true
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 12))
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }

                // Content preview
                Text(template.content)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
                    .lineLimit(2)

                // Category tag
                HStack {
                    Text(template.category.rawValue.uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white.opacity(DesignTokens.Opacity.overlayStrong))

                    Spacer()

                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundColor(.blue)
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
        .sheet(isPresented: $showShareSheet) {
            ShareTemplateView(template: template, isPresented: $showShareSheet)
        }
    }
}

// MARK: - Share Template View

struct ShareTemplateView: View {
    let template: ReplyTemplate
    @Binding var isPresented: Bool
    @State private var selectedShareType: ShareType = .publicAccess
    @State private var teamId: String = ""
    @State private var isSharing = false
    @State private var showSuccess = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "1C1C1E")
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Template Preview
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Share Template")
                                .font(.title2.bold())
                                .foregroundColor(.white)

                            Text(template.name)
                                .font(.headline)
                                .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))

                            Text(template.content)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))
                                .padding()
                                .background(Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
                                .cornerRadius(DesignTokens.Radius.button)
                        }

                        Divider()
                            .background(Color.white.opacity(DesignTokens.Opacity.overlayMedium))

                        // Share Type Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Share With")
                                .font(.headline)
                                .foregroundColor(.white)

                            // Public
                            ShareTypeButton(
                                icon: "globe",
                                title: "Public",
                                subtitle: "Anyone can use this template",
                                isSelected: selectedShareType == .publicAccess,
                                color: .blue
                            ) {
                                selectedShareType = .publicAccess
                            }

                            // Team
                            ShareTypeButton(
                                icon: "person.3.fill",
                                title: "Team",
                                subtitle: "Only your team members can use this",
                                isSelected: selectedShareType == .team,
                                color: .green
                            ) {
                                selectedShareType = .team
                            }

                            // Personal (already default)
                            ShareTypeButton(
                                icon: "lock.fill",
                                title: "Private",
                                subtitle: "Keep it private (current setting)",
                                isSelected: selectedShareType == .personal,
                                color: .gray
                            ) {
                                selectedShareType = .personal
                            }
                        }

                        // Share Button
                        Button {
                            shareTemplate()
                        } label: {
                            HStack {
                                if isSharing {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Share Template")
                                        .font(.headline)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedShareType == .personal ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(DesignTokens.Radius.button)
                        }
                        .disabled(isSharing || selectedShareType == .personal)

                        if let error = errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text(error)
                                    .foregroundColor(.red)
                                    .font(.caption)
                            }
                            .padding()
                            .background(Color.red.opacity(DesignTokens.Opacity.glassLight))
                            .cornerRadius(DesignTokens.Radius.chip)
                        }

                        if showSuccess {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Template shared successfully!")
                                    .foregroundColor(.green)
                                    .font(.headline)
                            }
                            .padding()
                            .background(Color.green.opacity(DesignTokens.Opacity.overlayLight))
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
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
                    }
                }
            }
        }
    }

    private func shareTemplate() {
        isSharing = true
        errorMessage = nil

        Task {
            do {
                _ = try await SharedTemplateService.shared.shareTemplate(
                    template,
                    shareType: selectedShareType,
                    teamId: selectedShareType == .team ? "team-123" : nil
                )

                await MainActor.run {
                    showSuccess = true
                    isSharing = false

                    let impact = UINotificationFeedbackGenerator()
                    impact.notificationOccurred(.success)

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        isPresented = false
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isSharing = false
                }
            }
        }
    }
}

struct ShareTypeButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? color : .white.opacity(DesignTokens.Opacity.overlayStrong))
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? color : .white.opacity(DesignTokens.Opacity.overlayMedium))
                    .font(.title3)
            }
            .padding()
            .background(isSelected ? color.opacity(DesignTokens.Opacity.overlayLight) : Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
            .cornerRadius(DesignTokens.Radius.button)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? color : Color.white.opacity(DesignTokens.Opacity.glassLight), lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Create Template View

struct CreateTemplateView: View {
    @Binding var isPresented: Bool
    @ObservedObject var templateManager = TemplateManager.shared

    @State private var name: String = ""
    @State private var content: String = ""
    @State private var selectedCategory: TemplateCategory = .general

    var isValid: Bool {
        !name.isEmpty && !content.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Template Name") {
                    TextField("e.g., Quick Confirm", text: $name)
                }

                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(TemplateCategory.allCases, id: \.self) { category in
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.rawValue)
                            }
                            .tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Reply Content") {
                    TextEditor(text: $content)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("New Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        templateManager.createTemplate(
                            name: name,
                            content: content,
                            category: selectedCategory
                        )
                        isPresented = false
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
}
