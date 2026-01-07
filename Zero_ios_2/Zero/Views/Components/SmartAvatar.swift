import SwiftUI

// MARK: - Smart Avatar View

/// World-class avatar system with intelligent fallbacks
/// Priority: Profile Image > Brand Logo > Styled Initials
struct SmartAvatar: View {
    let name: String
    let email: String?
    let imageUrl: String?
    let size: AvatarSize
    let showBadge: AvatarBadge?
    
    init(
        name: String,
        email: String? = nil,
        imageUrl: String? = nil,
        size: AvatarSize = .medium,
        badge: AvatarBadge? = nil
    ) {
        self.name = name
        self.email = email
        self.imageUrl = imageUrl
        self.size = size
        self.showBadge = badge
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            avatarContent
                .frame(width: size.dimension, height: size.dimension)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: avatarColor.opacity(0.3), radius: size.shadowRadius, y: 2)
            
            // Badge overlay
            if let badge = showBadge {
                badgeView(for: badge)
                    .offset(x: 2, y: 2)
            }
        }
    }
    
    // MARK: - Avatar Content
    
    @ViewBuilder
    private var avatarContent: some View {
        if let imageUrl = imageUrl, let url = URL(string: imageUrl) {
            // Profile image
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    fallbackAvatar
                case .empty:
                    ProgressView()
                        .frame(width: size.dimension, height: size.dimension)
                        .background(avatarColor.opacity(0.3))
                @unknown default:
                    fallbackAvatar
                }
            }
        } else if let brandLogo = getBrandLogo() {
            // Known brand logo
            brandLogoView(brandLogo)
        } else {
            // Styled initials fallback
            fallbackAvatar
        }
    }
    
    private var fallbackAvatar: some View {
        ZStack {
            // Gradient background based on name
            LinearGradient(
                colors: [avatarColor, avatarColor.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Subtle pattern overlay
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.15),
                            Color.clear
                        ],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: size.dimension
                    )
                )
            
            // Initials
            Text(initials)
                .font(size.font)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.2), radius: 1, y: 1)
        }
    }
    
    @ViewBuilder
    private func brandLogoView(_ brand: BrandInfo) -> some View {
        ZStack {
            // Brand color background
            brand.backgroundColor
            
            // Logo or letter
            if let systemImage = brand.systemImage {
                Image(systemName: systemImage)
                    .font(size.iconFont)
                    .foregroundColor(brand.foregroundColor)
            } else {
                Text(brand.initial)
                    .font(size.font)
                    .fontWeight(.bold)
                    .foregroundColor(brand.foregroundColor)
            }
        }
    }
    
    @ViewBuilder
    private func badgeView(for badge: AvatarBadge) -> some View {
        let badgeSize = size.badgeSize
        
        ZStack {
            Circle()
                .fill(badge.color)
                .frame(width: badgeSize, height: badgeSize)
            
            if let icon = badge.icon {
                Image(systemName: icon)
                    .font(.system(size: badgeSize * 0.5, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .overlay(
            Circle()
                .strokeBorder(Color.black.opacity(0.5), lineWidth: 1.5)
        )
    }
    
    // MARK: - Computed Properties
    
    private var initials: String {
        let components = name.split(separator: " ")
        if components.count >= 2 {
            let first = components[0].prefix(1)
            let last = components[1].prefix(1)
            return "\(first)\(last)".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
    
    private var avatarColor: Color {
        // Generate consistent color from name hash
        let hash = abs(name.hashValue)
        let colors: [Color] = [
            Color(red: 0.4, green: 0.5, blue: 0.9),   // Blue
            Color(red: 0.5, green: 0.3, blue: 0.7),   // Purple
            Color(red: 0.3, green: 0.6, blue: 0.5),   // Teal
            Color(red: 0.8, green: 0.4, blue: 0.4),   // Coral
            Color(red: 0.4, green: 0.7, blue: 0.4),   // Green
            Color(red: 0.9, green: 0.6, blue: 0.3),   // Orange
            Color(red: 0.6, green: 0.4, blue: 0.7),   // Lavender
            Color(red: 0.3, green: 0.5, blue: 0.7),   // Steel blue
        ]
        return colors[hash % colors.count]
    }
    
    // MARK: - Brand Detection
    
    private func getBrandLogo() -> BrandInfo? {
        guard let email = email?.lowercased() else { return nil }
        
        // Known brand patterns
        let brands: [(pattern: String, info: BrandInfo)] = [
            ("amazon", BrandInfo(
                initial: "a",
                systemImage: "shippingbox.fill",
                backgroundColor: Color(red: 1.0, green: 0.6, blue: 0.0),
                foregroundColor: .white
            )),
            ("google", BrandInfo(
                initial: "G",
                systemImage: nil,
                backgroundColor: .white,
                foregroundColor: Color(red: 0.26, green: 0.52, blue: 0.96)
            )),
            ("apple", BrandInfo(
                initial: "",
                systemImage: "apple.logo",
                backgroundColor: .black,
                foregroundColor: .white
            )),
            ("netflix", BrandInfo(
                initial: "N",
                systemImage: nil,
                backgroundColor: Color(red: 0.9, green: 0.1, blue: 0.1),
                foregroundColor: .white
            )),
            ("spotify", BrandInfo(
                initial: "",
                systemImage: "music.note",
                backgroundColor: Color(red: 0.12, green: 0.84, blue: 0.38),
                foregroundColor: .black
            )),
            ("linkedin", BrandInfo(
                initial: "in",
                systemImage: nil,
                backgroundColor: Color(red: 0.0, green: 0.47, blue: 0.71),
                foregroundColor: .white
            )),
            ("github", BrandInfo(
                initial: "",
                systemImage: "chevron.left.forwardslash.chevron.right",
                backgroundColor: Color(red: 0.14, green: 0.16, blue: 0.18),
                foregroundColor: .white
            )),
            ("slack", BrandInfo(
                initial: "#",
                systemImage: nil,
                backgroundColor: Color(red: 0.29, green: 0.16, blue: 0.36),
                foregroundColor: .white
            )),
            ("uber", BrandInfo(
                initial: "U",
                systemImage: nil,
                backgroundColor: .black,
                foregroundColor: .white
            )),
            ("airbnb", BrandInfo(
                initial: "",
                systemImage: "house.fill",
                backgroundColor: Color(red: 1.0, green: 0.35, blue: 0.42),
                foregroundColor: .white
            )),
            ("paypal", BrandInfo(
                initial: "PP",
                systemImage: nil,
                backgroundColor: Color(red: 0.0, green: 0.19, blue: 0.55),
                foregroundColor: .white
            )),
            ("stripe", BrandInfo(
                initial: "S",
                systemImage: nil,
                backgroundColor: Color(red: 0.39, green: 0.45, blue: 0.98),
                foregroundColor: .white
            )),
            ("twitter", BrandInfo(
                initial: "X",
                systemImage: nil,
                backgroundColor: .black,
                foregroundColor: .white
            )),
            ("facebook", BrandInfo(
                initial: "f",
                systemImage: nil,
                backgroundColor: Color(red: 0.06, green: 0.40, blue: 0.86),
                foregroundColor: .white
            )),
            ("instagram", BrandInfo(
                initial: "",
                systemImage: "camera.fill",
                backgroundColor: LinearGradient(
                    colors: [
                        Color(red: 0.51, green: 0.23, blue: 0.72),
                        Color(red: 0.88, green: 0.19, blue: 0.42),
                        Color(red: 0.99, green: 0.71, blue: 0.26)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ).asColor,
                foregroundColor: .white
            )),
        ]
        
        for (pattern, info) in brands {
            if email.contains(pattern) {
                return info
            }
        }
        
        return nil
    }
}

// MARK: - Supporting Types

enum AvatarSize {
    case small      // 32pt - list items
    case medium     // 44pt - cards
    case large      // 56pt - reader header
    case xlarge     // 80pt - profiles
    
    var dimension: CGFloat {
        switch self {
        case .small: return 32
        case .medium: return 44
        case .large: return 56
        case .xlarge: return 80
        }
    }
    
    var font: Font {
        switch self {
        case .small: return .system(size: 12, weight: .semibold)
        case .medium: return .system(size: 16, weight: .semibold)
        case .large: return .system(size: 20, weight: .semibold)
        case .xlarge: return .system(size: 28, weight: .semibold)
        }
    }
    
    var iconFont: Font {
        switch self {
        case .small: return .system(size: 14)
        case .medium: return .system(size: 18)
        case .large: return .system(size: 24)
        case .xlarge: return .system(size: 32)
        }
    }
    
    var badgeSize: CGFloat {
        switch self {
        case .small: return 10
        case .medium: return 14
        case .large: return 16
        case .xlarge: return 20
        }
    }
    
    var shadowRadius: CGFloat {
        switch self {
        case .small: return 2
        case .medium: return 4
        case .large: return 6
        case .xlarge: return 8
        }
    }
}

enum AvatarBadge {
    case vip
    case unread
    case online
    case verified
    case custom(color: Color, icon: String?)
    
    var color: Color {
        switch self {
        case .vip: return .yellow
        case .unread: return .blue
        case .online: return .green
        case .verified: return Color(red: 0.12, green: 0.7, blue: 1.0)
        case .custom(let color, _): return color
        }
    }
    
    var icon: String? {
        switch self {
        case .vip: return "star.fill"
        case .unread: return nil
        case .online: return nil
        case .verified: return "checkmark"
        case .custom(_, let icon): return icon
        }
    }
}

struct BrandInfo {
    let initial: String
    let systemImage: String?
    let backgroundColor: Color
    let foregroundColor: Color
}

// MARK: - Helper Extensions

private extension LinearGradient {
    /// Convert gradient to single color for simple backgrounds
    var asColor: Color {
        Color(red: 0.7, green: 0.3, blue: 0.5) // Fallback for gradient brands
    }
}

// MARK: - Avatar Group

/// Shows overlapping avatars for group/thread views
struct AvatarGroup: View {
    let avatars: [(name: String, email: String?)]
    let size: AvatarSize
    let maxVisible: Int
    
    init(
        avatars: [(name: String, email: String?)],
        size: AvatarSize = .small,
        maxVisible: Int = 4
    ) {
        self.avatars = avatars
        self.size = size
        self.maxVisible = maxVisible
    }
    
    var body: some View {
        HStack(spacing: -size.dimension * 0.3) {
            ForEach(Array(avatars.prefix(maxVisible).enumerated()), id: \.offset) { index, avatar in
                SmartAvatar(
                    name: avatar.name,
                    email: avatar.email,
                    size: size
                )
                .zIndex(Double(maxVisible - index))
            }
            
            // Overflow indicator
            if avatars.count > maxVisible {
                Text("+\(avatars.count - maxVisible)")
                    .font(size.font)
                    .foregroundColor(.white)
                    .frame(width: size.dimension, height: size.dimension)
                    .background(Color.gray.opacity(0.8))
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .strokeBorder(Color.white.opacity(0.3), lineWidth: 1.5)
                    )
            }
        }
    }
}

// MARK: - Preview

#Preview("Smart Avatars") {
    ScrollView {
        VStack(spacing: 24) {
            Text("Size Variants")
                .font(.headline)
            
            HStack(spacing: 16) {
                SmartAvatar(name: "John Doe", size: .small)
                SmartAvatar(name: "Jane Smith", size: .medium)
                SmartAvatar(name: "Bob Wilson", size: .large)
                SmartAvatar(name: "Alice Brown", size: .xlarge)
            }
            
            Divider()
            
            Text("Brand Logos")
                .font(.headline)
            
            HStack(spacing: 16) {
                SmartAvatar(name: "Amazon", email: "orders@amazon.com", size: .medium)
                SmartAvatar(name: "Google", email: "noreply@google.com", size: .medium)
                SmartAvatar(name: "Netflix", email: "info@netflix.com", size: .medium)
                SmartAvatar(name: "Spotify", email: "no-reply@spotify.com", size: .medium)
            }
            
            HStack(spacing: 16) {
                SmartAvatar(name: "GitHub", email: "noreply@github.com", size: .medium)
                SmartAvatar(name: "Apple", email: "noreply@apple.com", size: .medium)
                SmartAvatar(name: "LinkedIn", email: "messages@linkedin.com", size: .medium)
                SmartAvatar(name: "Stripe", email: "receipts@stripe.com", size: .medium)
            }
            
            Divider()
            
            Text("With Badges")
                .font(.headline)
            
            HStack(spacing: 16) {
                SmartAvatar(name: "VIP Sender", size: .large, badge: .vip)
                SmartAvatar(name: "Unread", size: .large, badge: .unread)
                SmartAvatar(name: "Online", size: .large, badge: .online)
                SmartAvatar(name: "Verified", size: .large, badge: .verified)
            }
            
            Divider()
            
            Text("Avatar Group")
                .font(.headline)
            
            AvatarGroup(
                avatars: [
                    ("John Doe", nil),
                    ("Jane Smith", nil),
                    ("Bob Wilson", nil),
                    ("Alice Brown", nil),
                    ("Charlie Green", nil),
                    ("Diana White", nil)
                ],
                size: .medium
            )
        }
        .padding()
    }
    .background(Color.black)
}

