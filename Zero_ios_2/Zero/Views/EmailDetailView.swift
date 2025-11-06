import SwiftUI

struct EmailDetailView: View {
    let card: EmailCard
    @SwiftUI.Environment(\.dismiss) var dismiss
    @State private var threadData: ThreadData?
    @State private var isLoadingThread = false
    @State private var threadExpanded = false
    @State private var showReplyComposer = false
    @State private var showDraftComposer = false
    @State private var replyText: String = ""
    @State private var showSnoozePicker = false
    @State private var snoozeDuration: Int = 2
    @State private var htmlRenderError: String?
    @State private var htmlContentHeight: CGFloat = 300
    @State private var showDebugDashboard = false
    @State private var selectedAttachment: EmailAttachment?
    @State private var showAttachmentPreview = false
    @State private var isVIP = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // Header section with frosted glass
                    headerSection
                        .padding(16)
                        .background(
                            ZStack {
                                Color.white.opacity(0.08)
                                Rectangle()
                                    .fill(.ultraThinMaterial)
                                    .opacity(0.4)
                            }
                        )
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                        )

                    // Subject in frosted glass panel
                    Text(card.title)
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            ZStack {
                                Color.white.opacity(0.06)
                                Rectangle()
                                    .fill(.ultraThinMaterial)
                                    .opacity(0.3)
                            }
                        )
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                        )

                    // Full Email Body (HTML or plain text) in frosted glass panel
                    VStack(alignment: .leading, spacing: 0) {
                        emailBodyContent
                            .frame(maxWidth: .infinity, alignment: .leading)

                        if let body = card.body, !body.isEmpty, card.htmlBody == nil || card.htmlBody!.isEmpty {
                            // Show plain text body with intelligent formatting
                            let _ = Logger.info("Rendering plain text body with formatting & URL detection, length: \(body.count)", category: .app)

                            // Apply intelligent formatting (lists, quotes, signatures)
                            let formattedBody = PlainTextFormatter.format(body)

                            // Shorten URLs to readable link text
                            let processedBody = URLShortener.shortenURLs(in: formattedBody, htmlBody: card.htmlBody)

                            LinkifiedText(
                                processedBody,
                                font: .body,
                                color: .white.opacity(0.92),
                                lineSpacing: 6
                            )
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                        } else {
                            // Fallback to summary
                            let _ = Logger.info("No body content, showing summary", category: .app)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Summary")
                                    .font(.caption.bold())
                                    .foregroundColor(.white.opacity(0.75))
                                    .tracking(0.5)

                                StructuredSummaryView(card: card)

                                Text("Note: Full email content not available")
                                    .font(.caption)
                                    .foregroundColor(.yellow.opacity(0.8))
                                    .padding(.top, 4)
                            }
                            .padding(16)
                        }
                    }
                    .background(
                        ZStack {
                            Color.white.opacity(0.06)
                            Rectangle()
                                .fill(.ultraThinMaterial)
                                .opacity(0.3)
                        }
                    )
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                    )

                    // Thread indicator (if part of thread)
                    if let threadLength = card.threadLength, threadLength > 1 {
                        threadIndicator(count: threadLength)
                            .padding(12)
                            .background(
                                ZStack {
                                    Color.white.opacity(0.06)
                                    Rectangle()
                                        .fill(.ultraThinMaterial)
                                        .opacity(0.3)
                                }
                            )
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                            )
                    }

                    // Calendar Invite section (if present)
                    if let calendarInvite = card.calendarInvite {
                        CalendarInviteView(
                            invite: calendarInvite,
                            onAddToCalendar: {
                                Task {
                                    do {
                                        try await CalendarService.shared.createEvent(from: calendarInvite, emailBody: card.body)
                                        Logger.info("✅ Calendar event created from invite", category: .action)
                                    } catch {
                                        Logger.error("Failed to create calendar event: \(error.localizedDescription)", category: .action)
                                    }
                                }
                            },
                            onJoinMeeting: calendarInvite.meetingUrl != nil ? {
                                if let urlString = calendarInvite.meetingUrl,
                                   let url = URL(string: urlString) {
                                    UIApplication.shared.open(url)
                                    Logger.info("🎥 Joined meeting: \(urlString)", category: .action)
                                }
                            } : nil
                        )
                        .padding(12)
                        .background(
                            ZStack {
                                Color.white.opacity(0.06)
                                Rectangle()
                                    .fill(.ultraThinMaterial)
                                    .opacity(0.3)
                            }
                        )
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                        )
                    }

                    // Attachments section (if present)
                    if let attachments = card.attachments, !attachments.isEmpty {
                        AttachmentListView(attachments: attachments) { attachment in
                            selectedAttachment = attachment
                            showAttachmentPreview = true
                        }
                        .padding(12)
                        .background(
                            ZStack {
                                Color.white.opacity(0.06)
                                Rectangle()
                                    .fill(.ultraThinMaterial)
                                    .opacity(0.3)
                            }
                        )
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                        )
                    }

                    // Thread context badges (if loaded)
                    if let threadData = threadData {
                        threadContextSection(context: threadData.context)
                            .padding(12)
                            .background(
                                ZStack {
                                    Color.white.opacity(0.06)
                                    Rectangle()
                                        .fill(.ultraThinMaterial)
                                        .opacity(0.3)
                                }
                            )
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                            )
                    }

                    // Thread messages (collapsed by default)
                    if let threadData = threadData {
                        threadMessagesSection(messages: threadData.messages)
                            .padding(12)
                            .background(
                                ZStack {
                                    Color.white.opacity(0.06)
                                    Rectangle()
                                        .fill(.ultraThinMaterial)
                                        .opacity(0.3)
                                }
                            )
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                            )
                    }

                    // Loading indicator
                    if isLoadingThread {
                        HStack {
                            ProgressView()
                            Text("Loading conversation...")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(
                            ZStack {
                                Color.white.opacity(0.06)
                                Rectangle()
                                    .fill(.ultraThinMaterial)
                                    .opacity(0.3)
                            }
                        )
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                        )
                    }

                    // Contextual Actions (smart suggestions)
                    ContextualActionsView(card: card)
                        .padding(12)
                        .background(
                            ZStack {
                                Color.white.opacity(0.06)
                                Rectangle()
                                    .fill(.ultraThinMaterial)
                                    .opacity(0.3)
                            }
                        )
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                        )

                    // AI Draft Composer button (only for unseen/seen emails)
                    if card.state == .unseen || card.state == .seen {
                        Button(action: { showDraftComposer = true }) {
                            HStack(spacing: 12) {
                                Image(systemName: "sparkles")
                                    .font(.title3)
                                    .foregroundColor(.white)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Draft a Reply with AI")
                                        .font(.headline)
                                        .foregroundColor(.white)

                                    Text("Generate a complete, context-aware draft")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                }

                                Spacer()

                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .padding(12)
                            .background(
                                ZStack {
                                    Color.white.opacity(0.08)
                                    Rectangle()
                                        .fill(.ultraThinMaterial)
                                        .opacity(0.4)
                                }
                            )
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    // Smart Replies (only for unseen/seen emails)
                    if card.state == .unseen || card.state == .seen {
                        SmartReplyView(email: card) { selectedReply in
                            replyText = selectedReply
                            showReplyComposer = true
                        }
                        .padding(12)
                        .background(
                            ZStack {
                                Color.white.opacity(0.06)
                                Rectangle()
                                    .fill(.ultraThinMaterial)
                                    .opacity(0.3)
                            }
                        )
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                        )
                    }

                    // Archetype-specific details
                    archetypeDetails
                        .padding(12)
                        .background(
                            ZStack {
                                Color.white.opacity(0.06)
                                Rectangle()
                                    .fill(.ultraThinMaterial)
                                    .opacity(0.3)
                            }
                        )
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                        )
                    
                    // Action buttons in frosted glass panel
                    actionButtons
                        .padding(16)
                        .background(
                            ZStack {
                                Color.white.opacity(0.08)
                                Rectangle()
                                    .fill(.ultraThinMaterial)
                                    .opacity(0.4)
                            }
                        )
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                        )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
            }
            .background(
                ZStack {
                    // Dark subtle background
                    LinearGradient(
                        colors: [
                            Color(red: 0x1a/255, green: 0x1a/255, blue: 0x2e/255),
                            Color(red: 0x2d/255, green: 0x1b/255, blue: 0x4e/255).opacity(0.8)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                }
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(.white)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        // VIP toggle button
                        Button {
                            toggleVIP()
                        } label: {
                            Image(systemName: isVIP ? "star.fill" : "star")
                                .foregroundColor(isVIP ? .yellow : .white)
                                .font(.title3)
                        }

                        Menu {
                            // Quick Actions Section
                            Button(action: {
                                Task {
                                    do {
                                        try await EmailAPIService.shared.performAction(emailId: card.id, action: .markRead)
                                        Logger.info("Email marked as read: \(card.id)", category: .email)
                                    } catch {
                                        Logger.error("Failed to mark as read: \(error)", category: .email)
                                    }
                                }
                            }) {
                                Label("Mark as Read", systemImage: "eye.fill")
                            }

                            Button(action: {
                                showSnoozePicker = true
                            }) {
                                Label("Snooze", systemImage: "clock.badge.checkmark")
                            }

                            Button(action: {
                                toggleVIP()
                            }) {
                                Label(isVIP ? "Remove from VIP" : "Add to VIP", systemImage: isVIP ? "star.slash" : "star")
                            }

                            Divider()

                            // Organize Section
                            Button(action: {
                                Task {
                                    do {
                                        try await EmailAPIService.shared.performAction(emailId: card.id, action: .archive)
                                        Logger.info("Email archived: \(card.id)", category: .email)
                                        await MainActor.run {
                                            dismiss()
                                        }
                                    } catch {
                                        Logger.error("Failed to archive: \(error)", category: .email)
                                    }
                                }
                            }) {
                                Label("Archive", systemImage: "archivebox.fill")
                            }

                            // Note: Mark as Unread and Spam actions not yet supported by API
                            // Button(action: {
                            //     Task {
                            //         do {
                            //             try await EmailAPIService.shared.performAction(emailId: card.id, action: .markUnread)
                            //             Logger.info("Email marked as unread: \(card.id)", category: .email)
                            //             await MainActor.run {
                            //                 dismiss()
                            //             }
                            //         } catch {
                            //             Logger.error("Failed to mark as unread: \(error)", category: .email)
                            //         }
                            //     }
                            // }) {
                            //     Label("Mark as Unread", systemImage: "envelope.badge.fill")
                            // }

                            // Button(action: {
                            //     Task {
                            //         do {
                            //             try await EmailAPIService.shared.performAction(emailId: card.id, action: .spam)
                            //             Logger.info("Email marked as spam: \(card.id)", category: .email)
                            //             await MainActor.run {
                            //                 dismiss()
                            //             }
                            //         } catch {
                            //             Logger.error("Failed to mark as spam: \(error)", category: .email)
                            //         }
                            //     }
                            // }) {
                            //     Label("Report Spam", systemImage: "exclamationmark.shield.fill")
                            // }

                            Divider()

                            // Developer Tools Section
                            Button(action: {
                                showDebugDashboard = true
                            }) {
                                Label("Debug Classification", systemImage: "ant.circle")
                            }

                            Divider()

                            // Delete Section
                            Button(role: .destructive, action: {
                                Task {
                                    do {
                                        try await EmailAPIService.shared.performAction(emailId: card.id, action: .delete)
                                        Logger.info("Email deleted: \(card.id)", category: .email)
                                        await MainActor.run {
                                            dismiss()
                                        }
                                    } catch {
                                        Logger.error("Failed to delete: \(error)", category: .email)
                                    }
                                }
                            }) {
                                Label("Delete", systemImage: "trash.fill")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle.fill")
                                .foregroundColor(.white)
                                .font(.title3)
                        }
                    }
                }
            }
            .task {
                // Load thread on-demand when view appears
                await loadThreadIfNeeded()
            }
            .onAppear {
                // Check VIP status
                if let email = card.sender?.email {
                    isVIP = VIPManager.shared.isVIP(email: email)
                }
            }
            .onDisappear {
                // CRITICAL: Clean up thread data to prevent memory leaks
                threadData = nil
                isLoadingThread = false
                htmlRenderError = nil
                Logger.info("EmailDetailView: Thread data cleaned up", category: .app)
            }
            .sheet(isPresented: $showReplyComposer) {
                ComposeReplyModal(card: card)
            }
            .sheet(isPresented: $showDraftComposer) {
                DraftComposerModal(
                    emailId: card.id,
                    emailSubject: card.title,
                    emailBody: card.body ?? card.summary,
                    senderName: senderName
                )
            }
            .sheet(isPresented: $showSnoozePicker) {
                SnoozeModal(card: card, isPresented: $showSnoozePicker)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .fullScreenCover(isPresented: $showDebugDashboard) {
                ClassificationDebugDashboard(card: card)
            }
            .fullScreenCover(isPresented: $showAttachmentPreview) {
                if let attachment = selectedAttachment {
                    AttachmentPreviewModal(
                        attachment: attachment,
                        isPresented: $showAttachmentPreview
                    )
                }
            }
        }
    }

    // MARK: - Thread Loading

    /// Thread cache to avoid redundant API calls
    private static var threadCache: [String: (data: ThreadData, timestamp: Date)] = [:]
    private static let cacheExpiration: TimeInterval = 300 // 5 minutes

    func loadThreadIfNeeded() async {
        // Only load if this is part of a thread (threadLength > 1)
        guard let threadLength = card.threadLength,
              threadLength > 1,
              threadData == nil else {
            return
        }

        // Check cache first
        if let cached = Self.threadCache[card.id] {
            // Check if cache is still valid (less than 5 minutes old)
            if Date().timeIntervalSince(cached.timestamp) < Self.cacheExpiration {
                threadData = cached.data
                Logger.info("Thread data loaded from cache", category: .app)
                return
            } else {
                // Remove expired cache entry
                Self.threadCache.removeValue(forKey: card.id)
            }
        }

        isLoadingThread = true

        do {
            let fetchedThread = try await EmailAPIService.shared.fetchThread(emailId: card.id)
            threadData = fetchedThread

            // Cache the result
            Self.threadCache[card.id] = (fetchedThread, Date())
            Logger.info("Thread data fetched and cached", category: .app)
        } catch {
            Logger.error("Failed to load thread: \(error)", category: .app)
            // Fail gracefully - email still shows, just without thread
        }

        isLoadingThread = false
    }

    /// Clear old cache entries (called periodically)
    static func cleanCache() {
        let now = Date()
        threadCache = threadCache.filter { _, value in
            now.timeIntervalSince(value.timestamp) < cacheExpiration
        }
        Logger.info("Thread cache cleaned, \(threadCache.count) entries remaining", category: .app)
    }

    // MARK: - Thread UI Components

    func threadIndicator(count: Int) -> some View {
        Button(action: {
            withAnimation {
                threadExpanded.toggle()
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 14))
                Text("\(count) messages in thread")
                    .font(.system(size: 14, weight: .medium))
                Spacer()
                Image(systemName: threadExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                    .font(.system(size: 16))
            }
            .foregroundColor(.white.opacity(0.9))
        }
        .buttonStyle(PlainButtonStyle())
    }

    func threadContextSection(context: ThreadContext) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack {
                Text("CONTEXT")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white.opacity(0.75))
                Spacer()
            }

            // Purchase badge
            if !context.purchases.isEmpty, let purchase = context.purchases.first {
                ContextBadge(
                    icon: "bag.fill",
                    iconColor: .green,
                    title: "Purchase History",
                    detail: "$\(String(format: "%.2f", purchase.amount ?? 0)) - \(purchase.invoiceNumber ?? "Order")"
                )
            }

            // Event badge
            if !context.upcomingEvents.isEmpty, let event = context.upcomingEvents.first {
                ContextBadge(
                    icon: "calendar",
                    iconColor: .blue,
                    title: "Upcoming Event",
                    detail: event.originalText
                )
            }

            // Location badge
            if !context.locations.isEmpty, let location = context.locations.first {
                LocationBadge(location: location)
            }

            // Unresolved question badge
            if !context.unresolvedQuestions.isEmpty, let question = context.unresolvedQuestions.first {
                ContextBadge(
                    icon: "questionmark.circle.fill",
                    iconColor: .orange,
                    title: "Pending Question",
                    detail: question.question
                )
            }
        }
    }

    func threadMessagesSection(messages: [ThreadMessage]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with expand/collapse
            Button(action: {
                withAnimation {
                    threadExpanded.toggle()
                }
            }) {
                HStack {
                    Text("CONVERSATION")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white.opacity(0.75))

                    Text("(\(messages.filter { !$0.isLatest }.count) previous)")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.55))

                    Spacer()

                    Image(systemName: threadExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.75))
                }
            }

            Divider()
                .background(Color.white.opacity(0.2))

            // Show messages when expanded
            if threadExpanded {
                ForEach(messages.filter { !$0.isLatest }) { message in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            SwiftUI.Text(message.from)
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                            Spacer()
                            SwiftUI.Text(message.date)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        SwiftUI.Text(message.body)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.85))
                            .lineLimit(3)
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(8)
                }
            } else {
                Text("[Tap to expand]")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))
                    .italic()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
        }
    }

    // MARK: - Email Body Rendering

    @ViewBuilder
    var emailBodyContent: some View {
        if let htmlBody = card.htmlBody, !htmlBody.isEmpty {
            // Show original HTML email with error handling
            let _ = Logger.info("Rendering HTML body, length: \(htmlBody.count)", category: .app)

            if let error = htmlRenderError {
                // Show error state with retry
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.yellow)

                    Text("Failed to render email content")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)

                    Button("Try Again") {
                        htmlRenderError = nil
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(8)
                }
                .frame(height: 300)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
            } else {
                HTMLWebView(
                    htmlContent: htmlBody,
                    onHeightChange: { height in
                        htmlContentHeight = max(height, 200)
                    },
                    onError: { error in
                        htmlRenderError = error
                    }
                )
                .frame(height: htmlContentHeight)
                .animation(.easeOut(duration: 0.2), value: htmlContentHeight)
            }
        }
    }

    var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // From
            HStack(spacing: 12) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(avatarColor)
                        .frame(width: 50, height: 50)
                    
                    Text(avatarInitial)
                        .font(.title3.bold())
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("From: \(senderName)")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text(card.timeAgo)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.75))
                }
            }
            
            // Priority badge
            HStack(spacing: 8) {
                Image(systemName: priorityIcon)
                    .font(.caption)
                Text(card.priority.rawValue.uppercased())
                    .font(.caption.bold())
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(priorityColor)
            .cornerRadius(8)
        }
    }
    
    var archetypeDetails: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Family specific
            if let kid = card.kid {
                detailRow(icon: "person.fill", label: "Student", value: "\(kid.name) - \(kid.grade)")
            }
            
            if card.requiresSignature == true {
                HStack(spacing: 12) {
                    Image(systemName: "doc.text.fill")
                        .foregroundColor(.white)
                    Text("Digital Signature Required")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                }
                .padding()
                .background(Color.white.opacity(0.2))
                .cornerRadius(12)
            }
            
            // Shopping specific - with size constraints and error handling
            if let productImageUrl = card.productImageUrl {
                AsyncImage(url: URL(string: productImageUrl)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)  // Changed from .fill to .fit for better portrait display
                            .frame(maxWidth: .infinity)  // Use full available width
                            .frame(maxHeight: 300)
                            .clipped()
                            .cornerRadius(12)
                    case .failure:
                        VStack {
                            Image(systemName: "photo.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white.opacity(0.3))
                            Text("Image failed to load")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                    case .empty:
                        ZStack {
                            Rectangle()
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 200)
                                .cornerRadius(12)
                            ProgressView()
                                .tint(.white)
                        }
                    @unknown default:
                        EmptyView()
                    }
                }
            }
            
            if let brand = card.brandName, let store = card.store {
                detailRow(icon: "bag.fill", label: "Store", value: store)
                detailRow(icon: "tag.fill", label: "Brand", value: brand)
            }
            
            if let salePrice = card.salePrice, let originalPrice = card.originalPrice {
                HStack(spacing: 12) {
                    Text("$\(String(format: "%.2f", salePrice))")
                        .font(.title.bold())
                        .foregroundColor(.white)
                    
                    Text("$\(String(format: "%.2f", originalPrice))")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.5))
                        .strikethrough()
                    
                    if let discount = card.discount {
                        Text("Save \(discount)%")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green)
                            .cornerRadius(6)
                    }
                }
            }
            
            // Sales specific
            if let company = card.company {
                detailRow(icon: "building.2.fill", label: "Company", value: company.name)
            }
            
            if let value = card.value, let probability = card.probability, let score = card.score {
                VStack(spacing: 12) {
                    detailRow(icon: "dollarsign.circle.fill", label: "Deal Value", value: value)
                    detailRow(icon: "percent", label: "Close Probability", value: "\(probability)%")
                    detailRow(icon: "star.fill", label: "Lead Score", value: "\(score)/100")
                }
                .padding()
                .background(Color.white.opacity(0.15))
                .cornerRadius(12)
            }
            
            // Travel specific
            if let airline = card.airline {
                detailRow(icon: "airplane", label: "Airline/Hotel", value: airline)
            }
        }
    }
    
    func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 24)

            Text(label + ":")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))

            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(.white)

            Spacer()
        }
    }
    
    var actionButtons: some View {
        VStack(spacing: 10) {
            // Primary action - wired to ActionRouter
            Button {
                // Get effective action and execute through ActionRouter
                if let action = getEffectiveActionForCard(card) {
                    Logger.info("Executing primary action: \(action.actionId)", category: .action)

                    // Execute through ActionRouter
                    ActionRouter.shared.executeAction(action, card: card)

                    // Dismiss after action
                    dismiss()
                } else {
                    Logger.warning("No action found for card: \(card.id)", category: .action)
                }
            } label: {
                HStack {
                    Image(systemName: "bolt.fill")
                    Text(card.hpa)
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.white)
                .foregroundColor(.blue)
                .cornerRadius(10)
            }

            // Secondary actions
            HStack(spacing: 10) {
                Button {
                    // Mark as seen
                    Task {
                        do {
                            try await EmailAPIService.shared.performAction(emailId: card.id, action: .markRead)
                            Logger.info("Email marked as read from action button", category: .email)
                            await MainActor.run {
                                dismiss()
                            }
                        } catch {
                            Logger.error("Failed to mark as read: \(error)", category: .email)
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "eye.fill")
                        Text("Mark Seen")
                            .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.15))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }

                Button {
                    // Show snooze picker
                    showSnoozePicker = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "moon.zzz.fill")
                        Text("Snooze")
                            .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.15))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
        }
    }

    // MARK: - Helper Methods

    /// Get effective action for card (checks for custom action override)
    private func getEffectiveActionForCard(_ card: EmailCard) -> EmailAction? {
        // Check if there's a custom action set for this card
        let customActions = UserDefaults.standard.dictionary(forKey: "customActions") as? [String: String] ?? [:]

        if let customActionId = customActions[card.id] {
            // Find the action with this ID in the card's suggested actions
            if let action = card.suggestedActions?.first(where: { $0.actionId == customActionId }) {
                return action
            }
        }

        // Otherwise return the primary suggested action
        if let primaryAction = card.suggestedActions?.first(where: { $0.isPrimary }) {
            return primaryAction
        }

        // Fallback to first action
        return card.suggestedActions?.first
    }
    
    // Computed properties for header
    var senderName: String {
        if let sender = card.sender {
            return sender.name
        } else if let kid = card.kid {
            return "\(kid.name)'s School"
        } else if let company = card.company {
            return company.name
        } else if let store = card.store {
            return store
        } else if let airline = card.airline {
            return airline
        }
        return "Unknown Sender"
    }
    
    var avatarInitial: String {
        if let sender = card.sender {
            return sender.initial
        } else if let kid = card.kid {
            return kid.initial
        } else if let company = card.company {
            return company.initials
        }
        return String(senderName.prefix(1))
    }
    
    var avatarColor: Color {
        // Use first color from v1.7 gradient
        switch card.type {
        case .mail: return Color(red: 0.388, green: 0.6, blue: 0.945)     // Blue
        case .ads: return Color(red: 0.063, green: 0.725, blue: 0.506)       // Green
        }
    }
    
    var priorityIcon: String {
        switch card.priority {
        case .critical: return "exclamationmark.3"
        case .high: return "exclamationmark.2"
        case .medium: return "exclamationmark"
        case .low: return "minus"
        }
    }
    
    var priorityColor: Color {
        switch card.priority {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .green
        }
    }

    // MARK: - VIP Management

    func toggleVIP() {
        guard let email = card.sender?.email else { return }

        isVIP = VIPManager.shared.toggleVIP(email: email)

        // Show feedback
        if isVIP {
            Logger.info("⭐ Added VIP: \(email)", category: .app)
        } else {
            Logger.info("Removed VIP: \(email)", category: .app)
        }
    }
}

