import SwiftUI

struct SearchModal: View {
    let viewModel: EmailViewModel
    @SwiftUI.Environment(\.dismiss) var dismiss
    @State private var searchQuery: String = ""
    @State private var results: [SearchResult] = []
    @State private var isSearching = false
    @State private var errorMessage: String?
    @State private var selectedEmail: EmailCard?
    @State private var selectedThread: SearchResult?
    @State private var isEditMode = false
    @State private var selectedThreads: Set<String> = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))

                    TextField("Search emails...", text: $searchQuery)
                        .textFieldStyle(.plain)
                        .foregroundColor(.white)
                        .submitLabel(.search)
                        .onSubmit {
                            performSearch()
                        }

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

                // Results
                if isSearching {
                    Spacer()
                    LoadingSpinner(text: "Searching...", size: .small)
                    Spacer()
                } else if let error = errorMessage {
                    Spacer()
                    CompactEmptyState(icon: "exclamationmark.triangle", message: error)
                    Spacer()
                } else if results.isEmpty && !searchQuery.isEmpty {
                    Spacer()
                    CompactEmptyState(icon: "magnifyingglass", message: "No results found")
                    Spacer()
                } else if results.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.largeTitle)
                            .foregroundColor(.white.opacity(DesignTokens.Opacity.overlayMedium))
                        Text("Search your emails")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Try searching by keyword, sender, or subject")
                            .font(.caption)
                            .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(results) { result in
                                ThreadResultRow(
                                    result: result,
                                    isEditMode: isEditMode,
                                    isSelected: selectedThreads.contains(result.threadId),
                                    onTap: {
                                        if isEditMode {
                                            // Toggle selection
                                            if selectedThreads.contains(result.threadId) {
                                                selectedThreads.remove(result.threadId)
                                            } else {
                                                selectedThreads.insert(result.threadId)
                                            }
                                        } else {
                                            // Open thread view if multi-message, else open single email
                                            if result.messageCount > 1 {
                                                selectedThread = result
                                            } else {
                                                selectedEmail = EmailCard(
                                                    id: result.latestEmail.id,
                                                    type: result.latestEmail.type,
                                                    state: result.latestEmail.state,
                                                    priority: result.latestEmail.priority,
                                                    hpa: result.latestEmail.hpa,
                                                    timeAgo: result.latestEmail.timeAgo,
                                                    title: result.latestEmail.title,
                                                    summary: result.latestEmail.summary,
                                                    metaCTA: "View Email",
                                                    threadLength: result.latestEmail.threadLength,
                                                    sender: result.latestEmail.sender
                                                )
                                            }
                                        }
                                    }
                                )
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
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isEditMode {
                        Button("Cancel") {
                            isEditMode = false
                            selectedThreads.removeAll()
                        }
                        .foregroundColor(.white)
                    } else {
                        Button("Close") {
                            dismiss()
                        }
                        .foregroundColor(.white)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if !results.isEmpty && !isEditMode {
                        Button("Select") {
                            isEditMode = true
                        }
                        .foregroundColor(.white)
                    } else if isEditMode {
                        Menu {
                            Button(action: { archiveSelected() }) {
                                Label("Archive", systemImage: "archivebox")
                            }
                            Button(action: { markSelectedAsRead() }) {
                                Label("Mark as Read", systemImage: "envelope.open")
                            }
                        } label: {
                            Text("Actions")
                                .foregroundColor(.white)
                        }
                        .disabled(selectedThreads.isEmpty)
                    }
                }
            }
            .sheet(item: $selectedEmail) { email in
                EmailDetailView(card: email)
            }
            .sheet(item: $selectedThread) { thread in
                EmailThreadView(thread: thread)
            }
        }
    }

    // MARK: - Bulk Actions

    func archiveSelected() {
        // Archive all selected threads
        for threadId in selectedThreads {
            Logger.info("📥 Archiving thread: \(threadId)", category: .app)
        }
        selectedThreads.removeAll()
        isEditMode = false
    }

    func markSelectedAsRead() {
        // Mark all selected threads as read
        for threadId in selectedThreads {
            Logger.info("Marking thread as read: \(threadId)", category: .app)
        }
        selectedThreads.removeAll()
        isEditMode = false
    }

    func performSearch() {
        guard !searchQuery.isEmpty else { return }

        isSearching = true
        errorMessage = nil

        Task {
            do {
                let useMockData = UserDefaults.standard.bool(forKey: "useMockData")

                let searchResults: [SearchResult]
                if useMockData {
                    // Mock mode - search locally through viewModel cards
                    searchResults = searchLocalCards(query: searchQuery)
                } else {
                    // Real email mode - search via API
                    searchResults = try await EmailAPIService.shared.searchEmails(query: searchQuery)
                }

                await MainActor.run {
                    results = searchResults
                    isSearching = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Search failed. Please try again."
                    isSearching = false
                }
            }
        }
    }

    // Search local cards for mock data mode
    private func searchLocalCards(query: String) -> [SearchResult] {
        let lowercasedQuery = query.lowercased()

        // Filter cards matching search query in title, summary, sender, or body
        let matchingCards = viewModel.cards.filter { card in
            card.title.lowercased().contains(lowercasedQuery) ||
            card.summary.lowercased().contains(lowercasedQuery) ||
            card.sender?.name.lowercased().contains(lowercasedQuery) ?? false ||
            card.company?.name.lowercased().contains(lowercasedQuery) ?? false ||
            card.body?.lowercased().contains(lowercasedQuery) ?? false
        }

        // Convert cards to SearchResult format
        return matchingCards.map { card in
            SearchResult(
                threadId: card.id,
                messageCount: card.threadLength ?? 1,
                latestEmail: SearchEmailPreview(
                    id: card.id,
                    type: card.type,
                    state: card.state,
                    priority: card.priority,
                    hpa: card.hpa,
                    timeAgo: card.timeAgo,
                    title: card.title,
                    summary: card.summary,
                    sender: card.sender,
                    threadLength: card.threadLength ?? 1
                ),
                allMessages: []
            )
        }
    }
}

struct ThreadResultRow: View {
    let result: SearchResult
    var isEditMode: Bool = false
    var isSelected: Bool = false
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Selection indicator in edit mode
                if isEditMode {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .blue : .white.opacity(0.4))
                        .font(.title2)
                }

                VStack(alignment: .leading, spacing: 12) {
                    // Header
                    HStack {
                    // Sender avatar
                    if let sender = result.latestEmail.sender {
                        Text(sender.initial)
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(DesignTokens.Radius.chip)

                        Text(sender.name)
                            .font(.headline)
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(DesignTokens.Opacity.glassLight))
                            .cornerRadius(DesignTokens.Radius.chip)

                        Text("Unknown")
                            .font(.headline)
                            .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
                    }

                    Spacer()

                    // Thread indicator
                    if result.messageCount > 1 {
                        HStack(spacing: 4) {
                            Image(systemName: "bubble.left.and.bubble.right")
                                .font(.system(size: 10))
                            Text("\(result.messageCount)")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(DesignTokens.Radius.minimal)
                    }

                    // Priority badge
                    priorityBadge(result.latestEmail.priority)
                }

                // Subject/Title
                Text(result.latestEmail.title)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .lineLimit(1)

                // Summary
                Text(result.latestEmail.summary)
                    .font(.caption)
                    .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
                    .lineLimit(2)

                // Time
                HStack {
                    Text(result.latestEmail.timeAgo)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(DesignTokens.Opacity.overlayStrong))

                    Spacer()

                    // Archetype badge
                    Text(result.latestEmail.type.displayName.uppercased())
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(DesignTokens.Opacity.glassLight))
                        .cornerRadius(DesignTokens.Radius.minimal)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.15) : Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                isSelected ? Color.blue.opacity(DesignTokens.Opacity.overlayStrong) : Color.white.opacity(DesignTokens.Opacity.glassLight),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    func priorityBadge(_ priority: Priority) -> some View {
        Group {
            switch priority {
            case .critical:
                Text("CRITICAL")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.red)
                    .cornerRadius(DesignTokens.Radius.minimal)
            case .high:
                Text("HIGH")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange)
                    .cornerRadius(DesignTokens.Radius.minimal)
            case .medium:
                EmptyView()
            case .low:
                EmptyView()
            }
        }
    }
}
