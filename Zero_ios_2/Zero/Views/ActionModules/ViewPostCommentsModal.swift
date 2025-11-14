import SwiftUI

struct Comment: Identifiable {
    let id = UUID()
    let authorName: String
    let authorInitial: String
    let timestamp: Date
    let content: String
    var likeCount: Int
    var isLiked: Bool = false
    var replies: [Comment] = []
}

struct ViewPostCommentsModal: View {
    let card: EmailCard
    @Binding var isPresented: Bool

    @State private var postTitle = ""
    @State private var postAuthor = ""
    @State private var comments: [Comment] = []
    @State private var newCommentText = ""
    @State private var replyingToCommentId: UUID?
    @State private var showCommentSuccess = false

    var body: some View {
        VStack(spacing: 0) {
            // Custom header bar
            HStack {
                Spacer()
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(DesignTokens.Colors.textSubtle)
                        .font(.title2)
                }
            }
            .padding()

            // Scrollable content
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.card) {
                    // Header
                    HStack {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.largeTitle)
                            .foregroundColor(.blue)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Comments")
                                .font(.title2.bold())
                                .foregroundColor(DesignTokens.Colors.textPrimary)

                            Text("\(totalCommentCount) \(totalCommentCount == 1 ? "comment" : "comments")")
                                .font(.subheadline)
                                .foregroundColor(DesignTokens.Colors.textSubtle)
                        }
                    }

                    Divider()
                        .background(Color.white.opacity(DesignTokens.Opacity.overlayMedium))

                    // Original Post Summary
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Original Post")
                                .font(.caption.bold())
                                .foregroundColor(DesignTokens.Colors.textSubtle)
                            Spacer()
                            Text("by \(postAuthor)")
                                .font(.caption)
                                .foregroundColor(DesignTokens.Colors.textSubtle)
                        }

                        Text(postTitle)
                            .font(.subheadline)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                            .lineSpacing(4)
                    }
                    .padding()
                    .background(Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
                    .cornerRadius(DesignTokens.Radius.button)

                    // Comments Section
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(comments) { comment in
                            CommentRow(
                                comment: comment,
                                isReplyingTo: replyingToCommentId == comment.id,
                                onLike: {
                                    toggleLike(commentId: comment.id)
                                },
                                onReply: {
                                    withAnimation(.spring()) {
                                        replyingToCommentId = comment.id
                                    }
                                }
                            )

                            // Show replies with indentation
                            if !comment.replies.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    ForEach(comment.replies) { reply in
                                        CommentRow(
                                            comment: reply,
                                            isReply: true,
                                            isReplyingTo: false,
                                            onLike: {
                                                toggleLike(commentId: reply.id, parentId: comment.id)
                                            },
                                            onReply: {}
                                        )
                                    }
                                }
                                .padding(.leading, 40)
                            }
                        }
                    }

                    // Add Comment Field
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(replyingToCommentId != nil ? "Write a Reply" : "Add a Comment")
                                .font(.headline)
                                .foregroundColor(DesignTokens.Colors.textPrimary)

                            if replyingToCommentId != nil {
                                Button {
                                    withAnimation(.spring()) {
                                        replyingToCommentId = nil
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "xmark.circle.fill")
                                        Text("Cancel")
                                    }
                                    .font(.caption)
                                    .foregroundColor(.red)
                                }
                            }
                        }

                        TextEditor(text: $newCommentText)
                            .frame(height: 80)
                            .padding()
                            .background(Color.white.opacity(DesignTokens.Opacity.glassLight))
                            .cornerRadius(DesignTokens.Radius.button)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                            .colorScheme(.dark)
                            .scrollContentBackground(.hidden)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                                    .strokeBorder(Color.white.opacity(DesignTokens.Opacity.overlayMedium), lineWidth: 1)
                            )

                        Button {
                            postComment()
                        } label: {
                            HStack {
                                Image(systemName: "paperplane.fill")
                                Text("Post Comment")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(newCommentText.isEmpty ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(DesignTokens.Radius.button)
                        }
                        .disabled(newCommentText.isEmpty)
                    }
                    .padding()
                    .background(Color.blue.opacity(DesignTokens.Opacity.glassLight))
                    .cornerRadius(DesignTokens.Radius.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
                            .strokeBorder(Color.blue.opacity(0.4), lineWidth: 1)
                    )

                    // Comment Success
                    if showCommentSuccess {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Comment posted!")
                                .foregroundColor(.green)
                                .font(.subheadline.bold())
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(DesignTokens.Opacity.overlayLight))
                        .cornerRadius(DesignTokens.Radius.button)
                    }

                    // Info message
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                            .font(.caption)
                        Text("Join the conversation! Like comments you appreciate and reply to continue the discussion.")
                            .font(.caption)
                            .foregroundColor(DesignTokens.Colors.textSubtle)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding()
                    .background(Color.blue.opacity(DesignTokens.Opacity.glassLight))
                    .cornerRadius(DesignTokens.Radius.button)
                }
                .padding(DesignTokens.Spacing.card)
            }
        }
        .onAppear {
            parseCommentsFromEmail()
        }
    }

    var totalCommentCount: Int {
        comments.count + comments.reduce(0) { $0 + $1.replies.count }
    }

    func parseCommentsFromEmail() {
        postTitle = card.summary
        postAuthor = card.sender?.name ?? "Community Member"

        // Generate sample comments (in production, these would come from the email/API)
        let now = Date()
        comments = [
            Comment(
                authorName: "John Doe",
                authorInitial: "J",
                timestamp: now.addingTimeInterval(-3600),
                content: "Great point! I completely agree with this perspective.",
                likeCount: 5,
                replies: [
                    Comment(
                        authorName: "Alice Smith",
                        authorInitial: "A",
                        timestamp: now.addingTimeInterval(-2400),
                        content: "Me too! This is really helpful.",
                        likeCount: 2
                    )
                ]
            ),
            Comment(
                authorName: "Maria Garcia",
                authorInitial: "M",
                timestamp: now.addingTimeInterval(-2700),
                content: "Thanks for sharing this. Very informative!",
                likeCount: 3
            ),
            Comment(
                authorName: "David Lee",
                authorInitial: "D",
                timestamp: now.addingTimeInterval(-1800),
                content: "I have a question about this - can you provide more details?",
                likeCount: 1,
                replies: [
                    Comment(
                        authorName: postAuthor,
                        authorInitial: String(postAuthor.prefix(1)),
                        timestamp: now.addingTimeInterval(-1200),
                        content: "Sure! Let me explain...",
                        likeCount: 4
                    )
                ]
            ),
            Comment(
                authorName: "Sarah Johnson",
                authorInitial: "S",
                timestamp: now.addingTimeInterval(-900),
                content: "This is exactly what our community needs. Thank you!",
                likeCount: 7
            )
        ]
    }

    func toggleLike(commentId: UUID, parentId: UUID? = nil) {
        if let parentId = parentId {
            // Toggle like on a reply
            if let parentIndex = comments.firstIndex(where: { $0.id == parentId }),
               let replyIndex = comments[parentIndex].replies.firstIndex(where: { $0.id == commentId }) {
                comments[parentIndex].replies[replyIndex].isLiked.toggle()
                if comments[parentIndex].replies[replyIndex].isLiked {
                    comments[parentIndex].replies[replyIndex].likeCount += 1
                } else {
                    comments[parentIndex].replies[replyIndex].likeCount = max(0, comments[parentIndex].replies[replyIndex].likeCount - 1)
                }
            }
        } else {
            // Toggle like on a top-level comment
            if let index = comments.firstIndex(where: { $0.id == commentId }) {
                comments[index].isLiked.toggle()
                if comments[index].isLiked {
                    comments[index].likeCount += 1
                } else {
                    comments[index].likeCount = max(0, comments[index].likeCount - 1)
                }
            }
        }

        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        Logger.info("Comment liked/unliked", category: .action)
    }

    func postComment() {
        Logger.info("Posting comment: \(newCommentText)", category: .action)

        let newComment = Comment(
            authorName: "You",
            authorInitial: "Y",
            timestamp: Date(),
            content: newCommentText,
            likeCount: 0
        )

        if let replyToId = replyingToCommentId,
           let parentIndex = comments.firstIndex(where: { $0.id == replyToId }) {
            // Add as reply
            comments[parentIndex].replies.append(newComment)
        } else {
            // Add as top-level comment
            comments.insert(newComment, at: 0)
        }

        // Show success
        withAnimation(.spring()) {
            showCommentSuccess = true
            newCommentText = ""
            replyingToCommentId = nil
        }

        // Haptic feedback
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)

        // Log analytics
        AnalyticsService.shared.log(
            .actionExecuted,
            parameters: [
                "action_id": "post_comment",
                "is_reply": replyingToCommentId != nil
            ]
        )

        // Hide success after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation(.spring()) {
                showCommentSuccess = false
            }
        }
    }
}

// MARK: - Comment Row

struct CommentRow: View {
    let comment: Comment
    var isReply: Bool = false
    let isReplyingTo: Bool
    let onLike: () -> Void
    let onReply: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                // Avatar
                Text(comment.authorInitial)
                    .font(.system(size: isReply ? 14 : 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: isReply ? 36 : 44, height: isReply ? 36 : 44)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 0.4, green: 0.49, blue: 0.92),
                                Color(red: 0.46, green: 0.29, blue: 0.64)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(isReply ? 18 : 22)

                VStack(alignment: .leading, spacing: 8) {
                    // Author and timestamp
                    HStack {
                        Text(comment.authorName)
                            .font(.subheadline.bold())
                            .foregroundColor(DesignTokens.Colors.textPrimary)

                        Text("•")
                            .foregroundColor(DesignTokens.Colors.textSubtle)

                        Text(timeAgo(from: comment.timestamp))
                            .font(.caption)
                            .foregroundColor(DesignTokens.Colors.textSubtle)
                    }

                    // Comment content
                    Text(comment.content)
                        .font(.subheadline)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    // Actions
                    HStack(spacing: 16) {
                        Button {
                            onLike()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: comment.isLiked ? "heart.fill" : "heart")
                                    .foregroundColor(comment.isLiked ? .pink : .white.opacity(DesignTokens.Opacity.textSubtle))
                                if comment.likeCount > 0 {
                                    Text("\(comment.likeCount)")
                                        .foregroundColor(comment.isLiked ? .pink : DesignTokens.Colors.textSubtle)
                                }
                            }
                            .font(.caption)
                        }

                        if !isReply {
                            Button {
                                onReply()
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "bubble.right")
                                    Text("Reply")
                                }
                                .font(.caption)
                                .foregroundColor(isReplyingTo ? .blue : .white.opacity(DesignTokens.Opacity.textSubtle))
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            isReplyingTo ? Color.blue.opacity(0.15) : Color.white.opacity(0.08)
        )
        .cornerRadius(DesignTokens.Radius.button)
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                .strokeBorder(
                    isReplyingTo ? Color.blue : Color.clear,
                    lineWidth: 2
                )
        )
    }

    func timeAgo(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let hours = Int(interval / 3600)

        if hours < 1 {
            let minutes = Int(interval / 60)
            return "\(minutes)m"
        } else if hours < 24 {
            return "\(hours)h"
        } else {
            let days = hours / 24
            return "\(days)d"
        }
    }
}

// MARK: - Preview

#Preview("View Post Comments Modal") {
    ViewPostCommentsModal(
        card: EmailCard(
            id: "preview",
            type: .mail,
            state: .seen,
            priority: .medium,
            hpa: "view_post_comments",
            timeAgo: "2h",
            title: "5 New Comments on Your Post",
            summary: "Great neighborhood meeting today! Thanks everyone who came out to discuss the new community garden project. We had over 50 residents attend and the energy was amazing.",
            body: "You have 5 new comments on your community post:\n\n1. John Doe: Great point! I completely agree with this perspective.\n2. Maria Garcia: Thanks for sharing this. Very informative!\n3. David Lee: I have a question about this - can you provide more details?\n4. Sarah Johnson: This is exactly what our community needs. Thank you!\n\nClick to view all comments and join the conversation.",
            metaCTA: "View",
            suggestedActions: [
                EmailAction(
                    actionId: "view_post_comments",
                    displayName: "View Comments",
                    actionType: .inApp,
                    isPrimary: true,
                    context: [:]
                )
            ],
            sender: SenderInfo(
                name: "Community Forum",
                initial: "C",
                email: "forum@community.org"
            )
        ),
        isPresented: .constant(true)
    )
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(
        LinearGradient(
            colors: [
                Color(red: 0.1, green: 0.1, blue: 0.2),
                Color(red: 0.05, green: 0.05, blue: 0.15)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}
