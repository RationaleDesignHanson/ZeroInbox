import SwiftUI

/**
 * ModalFieldViews - Reusable field components for GenericActionModal
 *
 * Provides 12+ field types with consistent styling:
 * - Text fields (single/multiline)
 * - Badges (monospaced codes/numbers)
 * - Status badges (colored states)
 * - Date/DateTime displays
 * - Currency displays
 * - Links, buttons, images
 * - Dividers
 */

// MARK: - Text Field View

struct TextFieldView: View {
    let label: String?
    let value: String?
    let placeholder: String?
    let copyable: Bool

    @State private var showCopied = false

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.element) {
            if let label = label {
                Text(label)
                    .font(DesignTokens.Typography.labelMedium)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }

            HStack {
                Text(value ?? placeholder ?? "—")
                    .font(DesignTokens.Typography.bodyMedium)
                    .foregroundColor(value != nil ? DesignTokens.Colors.textPrimary : DesignTokens.Colors.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if copyable && value != nil {
                    Button {
                        copyToClipboard(value!)
                    } label: {
                        Image(systemName: showCopied ? "checkmark.circle.fill" : "doc.on.doc")
                            .foregroundColor(showCopied ? .green : DesignTokens.Colors.textSecondary)
                    }
                }
            }
        }
    }

    private func copyToClipboard(_ text: String) {
        ClipboardUtility.copy(text)

        withAnimation {
            showCopied = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showCopied = false
            }
        }
    }
}

// MARK: - Multiline Text Field View

struct MultilineTextFieldView: View {
    let label: String?
    let value: String?
    let placeholder: String?

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.element) {
            if let label = label {
                Text(label)
                    .font(DesignTokens.Typography.labelMedium)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }

            Text(value ?? placeholder ?? "—")
                .font(DesignTokens.Typography.bodyMedium)
                .foregroundColor(value != nil ? DesignTokens.Colors.textPrimary : DesignTokens.Colors.textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Badge Field View

struct BadgeFieldView: View {
    let label: String?
    let value: String?
    let copyable: Bool

    @State private var showCopied = false

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.element) {
            if let label = label {
                Text(label)
                    .font(DesignTokens.Typography.labelMedium)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }

            HStack {
                Text(value ?? "—")
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.semibold)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .padding(.horizontal, DesignTokens.Spacing.element)
                    .padding(.vertical, DesignTokens.Spacing.minimal)
                    .background(Color(.systemGray5))
                    .cornerRadius(DesignTokens.Radius.chip)

                if copyable && value != nil {
                    Button {
                        copyToClipboard(value!)
                    } label: {
                        Image(systemName: showCopied ? "checkmark.circle.fill" : "doc.on.doc")
                            .foregroundColor(showCopied ? .green : DesignTokens.Colors.textSecondary)
                    }
                }

                Spacer()
            }
        }
    }

    private func copyToClipboard(_ text: String) {
        ClipboardUtility.copy(text)

        withAnimation {
            showCopied = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showCopied = false
            }
        }
    }
}

// MARK: - Status Badge Field View

struct StatusBadgeFieldView: View {
    let label: String?
    let value: String?
    let colorMapping: [String: String]?

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.element) {
            if let label = label {
                Text(label)
                    .font(DesignTokens.Typography.labelMedium)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }

            HStack {
                Text(value ?? "—")
                    .font(DesignTokens.Typography.labelMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, DesignTokens.Spacing.element)
                    .padding(.vertical, DesignTokens.Spacing.minimal)
                    .background(statusColor)
                    .cornerRadius(DesignTokens.Radius.chip)

                Spacer()
            }
        }
    }

    private var statusColor: Color {
        guard let value = value,
              let colorMapping = colorMapping,
              let colorName = colorMapping[value.lowercased()] else {
            return .gray
        }

        return colorFromString(colorName)
    }

    private func colorFromString(_ colorName: String) -> Color {
        switch colorName.lowercased() {
        case "red": return .red
        case "green": return .green
        case "blue": return .blue
        case "yellow": return .yellow
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "gray", "grey": return .gray
        default: return .gray
        }
    }
}

// MARK: - Date Field View

struct DateFieldView: View {
    let label: String?
    let date: Date?
    let formatting: FormattingRule?

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.element) {
            if let label = label {
                Text(label)
                    .font(DesignTokens.Typography.labelMedium)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }

            Text(formattedDate)
                .font(DesignTokens.Typography.bodyMedium)
                .foregroundColor(date != nil ? DesignTokens.Colors.textPrimary : DesignTokens.Colors.textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var formattedDate: String {
        guard let date = date else { return "—" }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")

        switch formatting?.type {
        case .dateRelative:
            return RelativeDateTimeFormatter().localizedString(for: date, relativeTo: Date())

        case .dateShort:
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)

        case .dateFull:
            formatter.dateFormat = "MMMM d, yyyy"
            return formatter.string(from: date)

        case .dateTime:
            formatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
            return formatter.string(from: date)

        default:
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
    }
}

// MARK: - DateTime Field View

struct DateTimeFieldView: View {
    let label: String?
    let date: Date?
    let formatting: FormattingRule?

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.element) {
            if let label = label {
                Text(label)
                    .font(DesignTokens.Typography.labelMedium)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }

            Text(formattedDateTime)
                .font(DesignTokens.Typography.bodyMedium)
                .foregroundColor(date != nil ? DesignTokens.Colors.textPrimary : DesignTokens.Colors.textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var formattedDateTime: String {
        guard let date = date else { return "—" }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")

        switch formatting?.type {
        case .dateTime:
            formatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
            return formatter.string(from: date)

        default:
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }
}

// MARK: - Currency Field View

struct CurrencyFieldView: View {
    let label: String?
    let value: String?

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.element) {
            if let label = label {
                Text(label)
                    .font(DesignTokens.Typography.labelMedium)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }

            Text(value ?? "—")
                .font(DesignTokens.Typography.headingLarge)
                .fontWeight(.bold)
                .foregroundColor(DesignTokens.Colors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Link Field View

struct LinkFieldView: View {
    let label: String?
    let url: String?

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.element) {
            if let label = label {
                Text(label)
                    .font(DesignTokens.Typography.labelMedium)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }

            if let url = url, let urlObj = URL(string: url) {
                Link(destination: urlObj) {
                    HStack {
                        Text(displayText)
                            .font(DesignTokens.Typography.bodyMedium)
                            .foregroundColor(DesignTokens.Colors.accentBlue)
                            .underline()

                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundColor(DesignTokens.Colors.accentBlue)

                        Spacer()
                    }
                }
            } else {
                Text("—")
                    .font(DesignTokens.Typography.bodyMedium)
                    .foregroundColor(DesignTokens.Colors.textTertiary)
            }
        }
    }

    private var displayText: String {
        guard let url = url else { return "—" }

        // Show domain name for cleaner display
        if let urlObj = URL(string: url), let host = urlObj.host {
            return host
        }

        return url
    }
}

// MARK: - Field Button View

struct FieldButtonView: View {
    let label: String

    var body: some View {
        Button {
            // Action handled by parent
        } label: {
            Text(label)
                .font(DesignTokens.Typography.bodyMedium)
                .foregroundColor(DesignTokens.Colors.accentBlue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignTokens.Spacing.element)
                .background(Color(.systemGray6))
                .cornerRadius(DesignTokens.Radius.chip)
        }
    }
}

// MARK: - Image Field View

struct ImageFieldView: View {
    let url: String?

    var body: some View {
        if let url = url, let imageURL = URL(string: url) {
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(height: 200)

                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(DesignTokens.Radius.card)

                case .failure:
                    Image(systemName: "photo")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                        .frame(height: 200)

                @unknown default:
                    EmptyView()
                }
            }
        } else {
            Image(systemName: "photo")
                .font(.system(size: 48))
                .foregroundColor(.gray)
                .frame(height: 200)
        }
    }
}

// MARK: - Previews

#if DEBUG
struct ModalFieldViews_Previews: PreviewProvider {
    static var previews: some View {
        Text("Preview not available - use in running app")
            .foregroundColor(.white)
    }
}
#endif
