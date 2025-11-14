import SwiftUI

struct EmailThreadView: View {
    let thread: SearchResult
    @SwiftUI.Environment(\.dismiss) var dismiss
    @State private var showReplyComposer = false
    @State private var selectedEmail: EmailCard?
    @State private var isArchiving = false
    @State private var showArchiveConfirmation = false
    @State private var isExpanded = false  // Thread collapse/expand state

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Thread header
                    threadHeaderView

                    // Latest message (always visible)
                    if let latestMessage = thread.allMessages.first {
                        ThreadMessageRow(
                            message: latestMessage,
                            isLatest: true,
                            onTap: {
                                selectedEmail = convertToEmailCard(latestMessage)
                            }
                        )
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }

                    // Collapse/Expand button for older messages
                    if thread.allMessages.count > 1 {
                        collapseExpandButton
                    }

                    // Older messages (collapsible)
                    if isExpanded {
                        ForEach(Array(thread.allMessages.dropFirst().enumerated()), id: \.element.id) { index, message in
                            ThreadMessageRow(
                                message: message,
                                isLatest: false,
                                isLast: index == thread.allMessages.count - 2,  // Check if last message
                                onTap: {
                                    selectedEmail = convertToEmailCard(message)
                                }
                            )
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .transition(.asymmetric(
                                insertion: .move(edge: .top).combined(with: .opacity),
                                removal: .move(edge: .top).combined(with: .opacity)
                            ))
                        }
                    }

                    Spacer(minLength: 100)
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
            .navigationTitle("Thread")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        // Archive thread button
                        Button(action: { showArchiveConfirmation = true }) {
                            Image(systemName: "archivebox")
                                .foregroundColor(.white)
                        }

                        // Reply button
                        Button(action: { showReplyComposer = true }) {
                            Image(systemName: "arrowshape.turn.up.left.fill")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .sheet(isPresented: $showReplyComposer) {
                ComposeReplyModal(card: convertToEmailCard(thread.latestEmail))
            }
            .sheet(item: $selectedEmail) { email in
                EmailDetailView(card: email)
            }
            .alert("Archive Thread?", isPresented: $showArchiveConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Archive", role: .destructive) {
                    archiveThread()
                }
            } message: {
                Text("Archive all \(thread.messageCount) messages in this thread?")
            }
        }
    }

    // MARK: - Collapse/Expand Button

    var collapseExpandButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isExpanded.toggle()
            }
        }) {
            HStack(spacing: 12) {
                // Visual connector line from latest message
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 2, height: 24)
                    .padding(.leading, 21)  // Align with timeline indicator

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)

                        Text(isExpanded ? "Hide earlier messages" : "Show \(thread.allMessages.count - 1) earlier messages")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)

                        Spacer()
                    }

                    Text(isExpanded ? "Collapse thread" : "Expand thread history")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Thread Header View

    var threadHeaderView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Subject
            Text(thread.latestEmail.title)
                .font(.title2.bold())
                .foregroundColor(.white)

            // Participant grid (2×2)
            if thread.allMessages.count > 1 {
                let participants = Array(Set(thread.allMessages.compactMap { $0.sender })).prefix(4)
                if participants.count > 1 {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        ForEach(Array(participants.enumerated()), id: \.element.email) { index, sender in
                            // TODO: AvatarBadge not in Xcode project - using placeholder
                            VStack {
                                Text(sender.initial)
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                                    .frame(width: 40, height: 40)
                                    .background(
                                        LinearGradient(
                                            colors: [.blue, .cyan],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .cornerRadius(8)
                                if index == 0 {
                                    Text("\(thread.messageCount)")
                                        .font(.caption2)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                        }
                    }
                    .frame(maxWidth: 200)
                }
            }

            // Thread stats
            HStack(spacing: 16) {
                // Message count
                HStack(spacing: 6) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.caption)
                    Text("\(thread.messageCount) messages")
                        .font(.caption)
                }
                .foregroundColor(.white.opacity(0.7))

                // Participants
                if thread.allMessages.count > 1 {
                    let participants = Set(thread.allMessages.compactMap { $0.sender?.name })
                    HStack(spacing: 6) {
                        Image(systemName: "person.2")
                            .font(.caption)
                        Text("\(participants.count) participants")
                            .font(.caption)
                    }
                    .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                // Archetype badge
                Text(thread.latestEmail.type.displayName.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        LinearGradient(
                            colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(6)
            }

            Divider()
                .background(Color.white.opacity(0.2))
        }
        .padding()
        .background(Color.white.opacity(0.05))
    }

    // MARK: - Actions

    func archiveThread() {
        isArchiving = true

        // Simulate archive operation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isArchiving = false
            dismiss()
        }
    }

    // MARK: - Conversion Helper

    func convertToEmailCard(_ preview: SearchEmailPreview) -> EmailCard {
        return EmailCard(
            id: preview.id,
            type: preview.type,
            state: preview.state,
            priority: preview.priority,
            hpa: preview.hpa,
            timeAgo: preview.timeAgo,
            title: preview.title,
            summary: preview.summary,
            body: preview.summary,  // Use summary as body for smart replies
            metaCTA: "View Email",
            threadLength: preview.threadLength,
            sender: preview.sender
        )
    }

    func convertToEmailCard(_ preview: SearchMessagePreview) -> EmailCard {
        return EmailCard(
            id: preview.id,
            type: preview.type,
            state: preview.state,
            priority: preview.priority,
            hpa: preview.hpa,
            timeAgo: preview.timeAgo,
            title: preview.title,
            summary: preview.summary,
            body: preview.summary,  // Use summary as body for smart replies
            metaCTA: "View Email",
            threadLength: preview.threadLength,
            sender: preview.sender
        )
    }
}

// MARK: - Thread Message Row

struct ThreadMessageRow: View {
    let message: SearchMessagePreview
    let isLatest: Bool
    var isLast: Bool = false  // Last message in thread
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            messageRowContent
        }
        .buttonStyle(PlainButtonStyle())
    }

    // Break down complex view to help compiler
    private var messageRowContent: some View {
        HStack(alignment: .top, spacing: 12) {
            timelineIndicator

            VStack(alignment: .leading, spacing: 8) {
                messageHeader
                messageSummary
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)
        }
        .padding()
        .background(messageBackground)
    }

    private var timelineIndicator: some View {
        VStack(spacing: 0) {
            // Top connector line (except for latest message)
            if !isLatest {
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 2, height: 20)
            }

            // Timeline circle
            ZStack {
                Circle()
                    .fill(isLatest ? Color.blue : Color.white.opacity(0.3))
                    .frame(width: 10, height: 10)

                // Outer ring for latest message
                if isLatest {
                    Circle()
                        .stroke(Color.blue.opacity(0.3), lineWidth: 3)
                        .frame(width: 18, height: 18)
                }
            }

            // Bottom connector line (except for last message)
            if !isLast {
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 2)
            } else {
                // End cap for last message
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 2, height: 20)
            }
        }
        .frame(width: 20)
    }

    private var messageHeader: some View {
        HStack {
            if let sender = message.sender {
                senderInfo(sender)
            }

            Spacer()

            if message.priority == .critical || message.priority == .high {
                priorityBadge(message.priority)
            }

            if isLatest {
                Text("LATEST")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue)
                    .cornerRadius(4)
            }
        }
    }

    private func senderInfo(_ sender: SenderInfo) -> some View {
        HStack(spacing: 8) {
            Text(sender.initial)
                .font(.caption.bold())
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 2) {
                Text(sender.name)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text(message.timeAgo)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var messageSummary: some View {
        Text(message.summary)
            .font(.caption)
            .foregroundColor(.white.opacity(0.8))
            .lineLimit(3)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var messageBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(isLatest ? Color.blue.opacity(0.1) : Color.white.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        isLatest ? Color.blue.opacity(0.3) : Color.white.opacity(0.1),
                        lineWidth: isLatest ? 2 : 1
                    )
            )
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
                    .cornerRadius(4)
            case .high:
                Text("HIGH")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange)
                    .cornerRadius(4)
            default:
                EmptyView()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let mockThread = SearchResult(
        threadId: "thread-1",
        messageCount: 3,
        latestEmail: SearchEmailPreview(
            id: "msg-1",
            type: .mail,
            state: .seen,
            priority: .high,
            hpa: "Sign & Send",
            timeAgo: "2 hours ago",
            title: "Field Trip Permission Form",
            summary: "Please sign the attached permission form for the upcoming field trip to the Science Museum.",
            sender: SenderInfo(name: "Mrs. Johnson", initial: "MJ", email: "teacher@school.edu"),
            threadLength: 3
        ),
        allMessages: [
            SearchMessagePreview(
                id: "msg-1",
                type: .mail,
                state: .seen,
                priority: .high,
                hpa: "Sign & Send",
                timeAgo: "2 hours ago",
                title: "Field Trip Permission Form",
                summary: "Please sign the attached permission form for the upcoming field trip to the Science Museum.",
                sender: SenderInfo(name: "Mrs. Johnson", initial: "MJ", email: "teacher@school.edu"),
                threadLength: 3
            ),
            SearchMessagePreview(
                id: "msg-2",
                type: .mail,
                state: .seen,
                priority: .medium,
                hpa: "Reply",
                timeAgo: "1 day ago",
                title: "Field Trip Permission Form",
                summary: "Here are the details about the upcoming field trip. Please let me know if you have any questions.",
                sender: SenderInfo(name: "Mrs. Johnson", initial: "MJ", email: "teacher@school.edu"),
                threadLength: 3
            ),
            SearchMessagePreview(
                id: "msg-3",
                type: .mail,
                state: .seen,
                priority: .medium,
                hpa: "Reply",
                timeAgo: "3 days ago",
                title: "Field Trip Permission Form",
                summary: "Initial announcement about the Science Museum field trip scheduled for next month.",
                sender: SenderInfo(name: "Mrs. Johnson", initial: "MJ", email: "teacher@school.edu"),
                threadLength: 3
            )
        ]
    )

    EmailThreadView(thread: mockThread)
}
