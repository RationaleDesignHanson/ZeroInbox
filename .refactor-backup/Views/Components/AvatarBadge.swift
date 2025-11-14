import SwiftUI

/// Reusable avatar badge with multiple badge variant support
/// Design system spec: 50×50pt primary, 32×32pt compact
struct AvatarBadge: View {
    let initial: String
    let gradient: Gradient
    let size: AvatarSize
    let threadCount: Int?
    let showUnreadDot: Bool
    let showVIPStar: Bool

    init(
        initial: String,
        gradient: Gradient = .mail,
        size: AvatarSize = .primary,
        threadCount: Int? = nil,
        showUnreadDot: Bool = false,
        showVIPStar: Bool = false
    ) {
        self.initial = initial
        self.gradient = gradient
        self.size = size
        self.threadCount = threadCount
        self.showUnreadDot = showUnreadDot
        self.showVIPStar = showVIPStar
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Base avatar with gradient
            Text(initial)
                .font(.system(size: size.fontSize, weight: .bold))
                .foregroundColor(.white)
                .frame(width: size.dimension, height: size.dimension)
                .background(
                    LinearGradient(
                        gradient: gradient.colors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(size.cornerRadius)
                .shadow(
                    color: gradient.shadowColor.opacity(0.3),
                    radius: 4,
                    x: 0,
                    y: 2
                )

            // Thread count badge (top priority)
            if let count = threadCount, count > 1 {
                Text("\(count)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 22, height: 22)
                    .background(Color.blue)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .strokeBorder(Color.black.opacity(0.3), lineWidth: 2)
                    )
                    .offset(x: 4, y: -4)
            }
            // Unread dot (if no thread count)
            else if showUnreadDot {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.black.opacity(0.3), lineWidth: 2)
                    )
                    .shadow(color: .blue.opacity(0.5), radius: 4, x: 0, y: 0)
                    .offset(x: 2, y: -2)
            }

            // VIP star (can coexist with others)
            if showVIPStar {
                Text("⭐")
                    .font(.system(size: 14))
                    .offset(x: 4, y: -4)
            }
        }
    }

    /// Convenience initializer from SenderInfo
    init(from sender: SenderInfo, size: AvatarSize = .primary, threadCount: Int? = nil, showUnreadDot: Bool = false, showVIPStar: Bool = false) {
        self.init(
            initial: sender.initial,
            gradient: .mail,  // Could be dynamic based on email type
            size: size,
            threadCount: threadCount,
            showUnreadDot: showUnreadDot,
            showVIPStar: showVIPStar
        )
    }
}

// MARK: - Avatar Size

enum AvatarSize {
    case primary
    case compact

    var dimension: CGFloat {
        switch self {
        case .primary: return 50
        case .compact: return 32
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .primary: return 12
        case .compact: return 8
        }
    }

    var fontSize: CGFloat {
        switch self {
        case .primary: return 18
        case .compact: return 14
        }
    }
}

// MARK: - Avatar Gradients

extension AvatarBadge {
    struct Gradient {
        let colors: SwiftUI.Gradient
        let shadowColor: Color

        static let mail = Gradient(
            colors: SwiftUI.Gradient(colors: [
                Color(red: 0.23, green: 0.51, blue: 0.96),  // #3b82f6
                Color(red: 0.02, green: 0.71, blue: 0.83)   // #06b6d4
            ]),
            shadowColor: Color(red: 0.23, green: 0.51, blue: 0.96)
        )

        static let ads = Gradient(
            colors: SwiftUI.Gradient(colors: [
                Color(red: 0.54, green: 0.36, blue: 0.97),  // #8b5cf6
                Color(red: 0.93, green: 0.28, blue: 0.58)   // #ec4899
            ]),
            shadowColor: Color(red: 0.54, green: 0.36, blue: 0.97)
        )

        static let vip = Gradient(
            colors: SwiftUI.Gradient(colors: [
                Color(red: 0.96, green: 0.62, blue: 0.04),  // #f59e0b
                Color(red: 0.94, green: 0.27, blue: 0.27)   // #ef4444
            ]),
            shadowColor: Color(red: 0.96, green: 0.62, blue: 0.04)
        )

        static let thread = Gradient(
            colors: SwiftUI.Gradient(colors: [
                Color(red: 0.54, green: 0.36, blue: 0.97),  // #8b5cf6
                Color(red: 0.93, green: 0.28, blue: 0.58)   // #ec4899
            ]),
            shadowColor: Color(red: 0.54, green: 0.36, blue: 0.97)
        )
    }
}

// MARK: - Preview

#Preview("Avatar Badge Variants") {
    ScrollView {
        VStack(spacing: 32) {
            // Section 1: Basic Variants
            VStack(alignment: .leading, spacing: 16) {
                Text("Basic Avatars")
                    .font(.headline)
                    .foregroundColor(.white)

                HStack(spacing: 32) {
                    VStack(spacing: 8) {
                        AvatarBadge(initial: "MJ", gradient: .mail)
                        Text("Initial Badge")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }

                    VStack(spacing: 8) {
                        AvatarBadge(
                            initial: "SC",
                            gradient: .thread,
                            threadCount: 5
                        )
                        Text("Thread Count")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }

                    VStack(spacing: 8) {
                        AvatarBadge(
                            initial: "ET",
                            gradient: .mail,
                            showUnreadDot: true
                        )
                        Text("Unread")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }

                    VStack(spacing: 8) {
                        AvatarBadge(
                            initial: "NK",
                            gradient: .vip,
                            showVIPStar: true
                        )
                        Text("VIP Contact")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }

            Divider()
                .background(Color.white.opacity(0.2))

            // Section 2: Size Variants
            VStack(alignment: .leading, spacing: 16) {
                Text("Size Variants")
                    .font(.headline)
                    .foregroundColor(.white)

                HStack(spacing: 32) {
                    VStack(spacing: 8) {
                        AvatarBadge(
                            initial: "AB",
                            gradient: .mail,
                            size: .primary
                        )
                        Text("Primary (50pt)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }

                    VStack(spacing: 8) {
                        AvatarBadge(
                            initial: "CD",
                            gradient: .mail,
                            size: .compact
                        )
                        Text("Compact (32pt)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }

            Divider()
                .background(Color.white.opacity(0.2))

            // Section 3: Gradient Variants
            VStack(alignment: .leading, spacing: 16) {
                Text("Gradient Types")
                    .font(.headline)
                    .foregroundColor(.white)

                HStack(spacing: 24) {
                    VStack(spacing: 8) {
                        AvatarBadge(initial: "MA", gradient: .mail)
                        Text("Mail")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }

                    VStack(spacing: 8) {
                        AvatarBadge(initial: "AD", gradient: .ads)
                        Text("Ads")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }

                    VStack(spacing: 8) {
                        AvatarBadge(initial: "VI", gradient: .vip)
                        Text("VIP")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }

                    VStack(spacing: 8) {
                        AvatarBadge(initial: "TH", gradient: .thread)
                        Text("Thread")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
        }
        .padding(32)
    }
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
