import Foundation

/// Time range for filtering emails
enum EmailTimeRange: String, CaseIterable, Codable {
    case threeDays = "3 Days"
    case oneWeek = "1 Week"
    case twoWeeks = "2 Weeks"  // Default
    case threeWeeks = "3 Weeks"
    case oneMonth = "1 Month"
    case sixWeeks = "6 Weeks"
    case twoMonths = "2 Months"
    case threeMonths = "3 Months"

    /// Number of days for this time range
    var days: Int {
        switch self {
        case .threeDays: return 3
        case .oneWeek: return 7
        case .twoWeeks: return 14
        case .threeWeeks: return 21
        case .oneMonth: return 30
        case .sixWeeks: return 42
        case .twoMonths: return 60
        case .threeMonths: return 90
        }
    }

    /// Calculate the "after" date for Gmail API filtering
    /// Returns date in YYYY/MM/DD format
    var afterDate: String {
        let calendar = Calendar.current
        let today = Date()

        guard let targetDate = calendar.date(byAdding: .day, value: -days, to: today) else {
            return formatDate(today)
        }

        return formatDate(targetDate)
    }

    /// Format date as YYYY/MM/DD for Gmail API
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: date)
    }

    /// Display text for UI
    var displayText: String {
        return rawValue
    }
}
