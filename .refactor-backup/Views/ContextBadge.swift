import SwiftUI

/// Context badge for displaying thread context information
struct ContextBadge: View {
    let icon: String
    let iconColor: Color
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(iconColor)
                .frame(width: 32, height: 32)
                .background(iconColor.opacity(0.2))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))

                Text(detail)
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

#Preview("Context Badge") {
    ZStack {
        LinearGradient(
            colors: [
                Color(red: 0.1, green: 0.1, blue: 0.15),
                Color(red: 0.15, green: 0.15, blue: 0.2)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack(spacing: 16) {
            ContextBadge(
                icon: "calendar",
                iconColor: .blue,
                title: "Event",
                detail: "Parent-Teacher Conference on Oct 25 at 3:00 PM"
            )

            ContextBadge(
                icon: "person.2",
                iconColor: .green,
                title: "Attendees",
                detail: "Sarah Johnson, Mike Chen, and 3 others"
            )
        }
        .padding()
    }
}

#Preview("Location Badge") {
    ZStack {
        LinearGradient(
            colors: [
                Color(red: 0.1, green: 0.1, blue: 0.15),
                Color(red: 0.15, green: 0.15, blue: 0.2)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        LocationBadge(
            location: Location(
                address: "123 Main St, Springfield, IL 62701",
                phone: "+1 (555) 123-4567",
                messageId: "preview-location-123"
            )
        )
        .padding()
    }
}

/// Location badge with call and directions buttons
struct LocationBadge: View {
    let location: Location

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: "location.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.red)
                    .frame(width: 32, height: 32)
                    .background(Color.red.opacity(0.2))
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Location")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))

                    if let address = location.address {
                        Text(address)
                            .font(.system(size: 13))
                            .foregroundColor(.white)
                            .lineLimit(2)
                    }

                    if let phone = location.phone {
                        Text(phone)
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }

                Spacer()
            }

            // Action buttons
            HStack(spacing: 12) {
                if let phone = location.phone {
                    Button(action: {
                        let cleanPhone = phone.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
                        if let url = URL(string: "tel:\(cleanPhone)") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Label("Call", systemImage: "phone.fill")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                }

                if let address = location.address {
                    Button(action: {
                        let encodedAddress = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                        if let url = URL(string: "maps://?address=\(encodedAddress)") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Label("Directions", systemImage: "map.fill")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                }

                Spacer()
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}
