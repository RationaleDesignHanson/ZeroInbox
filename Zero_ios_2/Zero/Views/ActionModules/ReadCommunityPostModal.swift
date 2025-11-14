import SwiftUI

struct CommunityPost {
    let authorName: String
    let authorInitial: String
    let timestamp: Date
    let content: String
    var likeCount: Int
    var commentCount: Int
    var isLiked: Bool = false
}

struct ReadCommunityPostModal: View {
    let card: EmailCard
    @Binding var isPresented: Bool

    @State private var post: CommunityPost?
    @State private var showReplyField = false
    @State private var replyText = ""
    @State private var showReplySuccess = false

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
                        Image(systemName: "newspaper.fill")
                            .font(.largeTitle)
                            .foregroundColor(.blue)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Community Post")
                                .font(.title2.bold())
                                .foregroundColor(DesignTokens.Colors.textPrimary)

                            Text(card.sender?.name ?? "Community Member")
                                .font(.subheadline)
                                .foregroundColor(DesignTokens.Colors.textSubtle)
                        }
                    }

                    Divider()
                        .background(Color.white.opacity(DesignTokens.Opacity.overlayMedium))

                    if let post = post {
                        // Post Card
                        VStack(alignment: .leading, spacing: 16) {
                            // Author info
                            HStack(spacing: 12) {
                                // Avatar
                                Text(post.authorInitial)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 50, height: 50)
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
                                    .cornerRadius(25)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(post.authorName)
                                        .font(.headline)
                                        .foregroundColor(DesignTokens.Colors.textPrimary)

                                    Text(timeAgo(from: post.timestamp))
                                        .font(.caption)
                                        .foregroundColor(DesignTokens.Colors.textSubtle)
                                }

                                Spacer()
                            }

                            // Post content
                            Text(post.content)
                                .font(.subheadline)
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)

                            // Engagement stats
                            HStack(spacing: 24) {
                                HStack(spacing: 6) {
                                    Image(systemName: "heart.fill")
                                        .foregroundColor(.pink)
                                        .font(.caption)
                                    Text("\(post.likeCount)")
                                        .font(.caption)
                                        .foregroundColor(DesignTokens.Colors.textSubtle)
                                }

                                HStack(spacing: 6) {
                                    Image(systemName: "bubble.right.fill")
                                        .foregroundColor(.blue)
                                        .font(.caption)
                                    Text("\(post.commentCount) \(post.commentCount == 1 ? "comment" : "comments")")
                                        .font(.caption)
                                        .foregroundColor(DesignTokens.Colors.textSubtle)
                                }
                            }

                            Divider()
                                .background(Color.white.opacity(DesignTokens.Opacity.overlayLight))

                            // Action buttons
                            HStack(spacing: 12) {
                                Button {
                                    toggleLike()
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: post.isLiked ? "heart.fill" : "heart")
                                            .foregroundColor(post.isLiked ? .pink : .white)
                                        Text(post.isLiked ? "Liked" : "Like")
                                            .font(.subheadline.bold())
                                            .foregroundColor(post.isLiked ? .pink : DesignTokens.Colors.textPrimary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(post.isLiked ? Color.pink.opacity(DesignTokens.Opacity.overlayLight) : Color.white.opacity(DesignTokens.Opacity.glassLight))
                                    .cornerRadius(DesignTokens.Radius.button)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                                            .strokeBorder(post.isLiked ? Color.pink : Color.white.opacity(DesignTokens.Opacity.overlayMedium), lineWidth: 1)
                                    )
                                }

                                Button {
                                    withAnimation(.spring()) {
                                        showReplyField.toggle()
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "bubble.right")
                                        Text("Comment")
                                            .font(.subheadline.bold())
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue.opacity(DesignTokens.Opacity.overlayLight))
                                    .foregroundColor(.blue)
                                    .cornerRadius(DesignTokens.Radius.button)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                                            .strokeBorder(Color.blue, lineWidth: 1)
                                    )
                                }
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(DesignTokens.Radius.card)

                        // Reply field
                        if showReplyField {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Write a Comment")
                                    .font(.headline)
                                    .foregroundColor(DesignTokens.Colors.textPrimary)

                                TextEditor(text: $replyText)
                                    .frame(height: 100)
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

                                HStack(spacing: 12) {
                                    Button {
                                        withAnimation(.spring()) {
                                            showReplyField = false
                                            replyText = ""
                                        }
                                    } label: {
                                        Text("Cancel")
                                            .font(.subheadline)
                                            .foregroundColor(DesignTokens.Colors.textSubtle)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 12)
                                            .background(Color.white.opacity(DesignTokens.Opacity.glassLight))
                                            .cornerRadius(DesignTokens.Radius.button)
                                    }

                                    Button {
                                        postComment()
                                    } label: {
                                        HStack {
                                            Image(systemName: "paperplane.fill")
                                            Text("Post Comment")
                                                .font(.subheadline.bold())
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(replyText.isEmpty ? Color.gray : Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(DesignTokens.Radius.button)
                                    }
                                    .disabled(replyText.isEmpty)
                                }
                            }
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        // Comment success
                        if showReplySuccess {
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

                        // Share button
                        Button {
                            sharePost()
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share Post")
                                    .font(.subheadline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(DesignTokens.Opacity.glassLight))
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                            .cornerRadius(DesignTokens.Radius.button)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                                    .strokeBorder(Color.white.opacity(DesignTokens.Opacity.overlayMedium), lineWidth: 1)
                            )
                        }
                    }

                    // Info message
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                            .font(.caption)
                        Text("Engage with your community by liking and commenting on posts. Your interactions help build a stronger neighborhood connection.")
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
            parsePost()
        }
    }

    func parsePost() {
        // Extract post details from email
        let authorName = card.sender?.name ?? "Community Member"
        let authorInitial = String(authorName.prefix(1))
        let content = card.summary

        // Try to extract engagement stats
        var likeCount = 0
        var commentCount = 0

        let text = card.body ?? card.summary
        if let likesMatch = text.range(of: #"(\d+)\s*(?:like|❤️)"#, options: .regularExpression) {
            if let count = Int(text[likesMatch].filter { $0.isNumber }) {
                likeCount = count
            }
        }
        if let commentsMatch = text.range(of: #"(\d+)\s*comment"#, options: .regularExpression) {
            if let count = Int(text[commentsMatch].filter { $0.isNumber }) {
                commentCount = count
            }
        }

        post = CommunityPost(
            authorName: authorName,
            authorInitial: authorInitial,
            timestamp: Date(),
            content: content,
            likeCount: likeCount,
            commentCount: commentCount
        )
    }

    func timeAgo(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let hours = Int(interval / 3600)

        if hours < 1 {
            let minutes = Int(interval / 60)
            return "\(minutes) \(minutes == 1 ? "minute" : "minutes") ago"
        } else if hours < 24 {
            return "\(hours) \(hours == 1 ? "hour" : "hours") ago"
        } else {
            let days = hours / 24
            return "\(days) \(days == 1 ? "day" : "days") ago"
        }
    }

    func toggleLike() {
        guard var currentPost = post else { return }

        withAnimation(.spring(response: 0.3)) {
            currentPost.isLiked.toggle()
            if currentPost.isLiked {
                currentPost.likeCount += 1
            } else {
                currentPost.likeCount = max(0, currentPost.likeCount - 1)
            }
            post = currentPost
        }

        Logger.info("Post \(currentPost.isLiked ? "liked" : "unliked")", category: .action)

        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        // Log analytics
        AnalyticsService.shared.log(
            .actionExecuted,
            parameters: [
                "action_id": "like_post",
                "liked": currentPost.isLiked
            ]
        )
    }

    func postComment() {
        Logger.info("Posting comment: \(replyText)", category: .action)

        // Update comment count
        if var currentPost = post {
            currentPost.commentCount += 1
            post = currentPost
        }

        // Show success
        withAnimation(.spring()) {
            showReplySuccess = true
            showReplyField = false
            replyText = ""
        }

        // Haptic feedback
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)

        // Log analytics
        AnalyticsService.shared.log(
            .actionExecuted,
            parameters: [
                "action_id": "comment_post",
                "comment_length": replyText.count
            ]
        )

        // Hide success after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation(.spring()) {
                showReplySuccess = false
            }
        }
    }

    func sharePost() {
        guard let post = post else { return }

        let shareText = """
        Community Post by \(post.authorName)

        \(post.content)

        Posted \(timeAgo(from: post.timestamp))
        ❤️ \(post.likeCount) likes · 💬 \(post.commentCount) comments
        """

        UIPasteboard.general.string = shareText
        Logger.info("Post copied to clipboard", category: .action)

        // Haptic feedback
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)
    }
}

// MARK: - Preview

#Preview("Read Community Post Modal") {
    ReadCommunityPostModal(
        card: EmailCard(
            id: "preview",
            type: .mail,
            state: .seen,
            priority: .medium,
            hpa: "read_community_post",
            timeAgo: "2h",
            title: "New Post in Your Community",
            summary: "Great neighborhood meeting today! Thanks everyone who came out to discuss the new community garden project. We had over 50 residents attend and the energy was amazing. Looking forward to breaking ground next month! 🌱 Let's make our neighborhood greener together.",
            body: "Sarah Johnson posted 2 hours ago:\n\nGreat neighborhood meeting today! Thanks everyone who came out to discuss the new community garden project. We had over 50 residents attend and the energy was amazing. Looking forward to breaking ground next month! 🌱\n\nLet's make our neighborhood greener together.\n\n❤️ 12 likes · 💬 5 comments",
            metaCTA: "View",
            suggestedActions: [
                EmailAction(
                    actionId: "read_community_post",
                    displayName: "Read Post",
                    actionType: .inApp,
                    isPrimary: true,
                    context: [:]
                )
            ],
            sender: SenderInfo(
                name: "Sarah Johnson",
                initial: "S",
                email: "sarah@community.org"
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
