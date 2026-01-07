import Foundation

/// Service for tracking model tuning feedback rewards
/// Users earn free months by providing quality feedback to improve the ML models
/// Incentive: 10 cards of feedback = 1 free month of Zero subscription
class ModelTuningRewardsService {
    static let shared = ModelTuningRewardsService()

    private let cardsPerFreeMonth = 10
    private let userDefaults = UserDefaults.standard

    // UserDefaults keys
    private let feedbackCountKey = "model_tuning_feedback_count"
    private let earnedMonthsKey = "model_tuning_earned_months"
    private let currentMonthProgressKey = "model_tuning_current_month_progress"
    private let lastFeedbackDateKey = "model_tuning_last_feedback_date"
    private let feedbackHistoryKey = "model_tuning_feedback_history"

    // MARK: - Progress Tracking

    /// Total number of feedback submissions (all time)
    var totalFeedbackCount: Int {
        get { userDefaults.integer(forKey: feedbackCountKey) }
        set { userDefaults.set(newValue, forKey: feedbackCountKey) }
    }

    /// Number of free months earned (all time)
    var earnedMonths: Int {
        get { userDefaults.integer(forKey: earnedMonthsKey) }
        set { userDefaults.set(newValue, forKey: earnedMonthsKey) }
    }

    /// Progress toward next free month (0-9, resets to 0 when month is earned)
    var currentMonthProgress: Int {
        get { userDefaults.integer(forKey: currentMonthProgressKey) }
        set { userDefaults.set(newValue, forKey: currentMonthProgressKey) }
    }

    /// Last feedback submission date
    var lastFeedbackDate: Date? {
        get { userDefaults.object(forKey: lastFeedbackDateKey) as? Date }
        set { userDefaults.set(newValue, forKey: lastFeedbackDateKey) }
    }

    // MARK: - Submit Feedback

    /// Records a feedback submission and updates progress
    /// Returns true if a new month was earned
    @discardableResult
    func recordFeedback() -> Bool {
        totalFeedbackCount += 1
        currentMonthProgress += 1
        lastFeedbackDate = Date()

        // Track feedback history for analytics
        saveFeedbackHistory()

        // Check if user earned a free month
        if currentMonthProgress >= cardsPerFreeMonth {
            earnedMonths += 1
            currentMonthProgress = 0

            Logger.info("🎉 User earned free month #\(earnedMonths)!", category: .app)
            return true
        }

        Logger.info("Feedback recorded: \(currentMonthProgress)/\(cardsPerFreeMonth) toward next free month", category: .app)
        return false
    }

    // MARK: - Progress Queries

    /// Progress percentage toward next free month (0.0 - 1.0)
    var progressPercentage: Double {
        return Double(currentMonthProgress) / Double(cardsPerFreeMonth)
    }

    /// Number of cards remaining until next free month
    var cardsRemaining: Int {
        return cardsPerFreeMonth - currentMonthProgress
    }

    /// Human-readable progress string
    var progressText: String {
        return "\(currentMonthProgress) of \(cardsPerFreeMonth) cards"
    }

    /// Human-readable earned months text
    var earnedMonthsText: String {
        if earnedMonths == 0 {
            return "No free months yet"
        } else if earnedMonths == 1 {
            return "1 free month earned"
        } else {
            return "\(earnedMonths) free months earned"
        }
    }

    // MARK: - Feedback History

    private struct FeedbackHistoryItem: Codable {
        let date: Date
        let cumulativeCount: Int
    }

    /// Saves feedback submission to history for analytics
    private func saveFeedbackHistory() {
        var history = loadFeedbackHistory()
        history.append(FeedbackHistoryItem(date: Date(), cumulativeCount: totalFeedbackCount))

        // Keep only last 100 entries to avoid bloat
        if history.count > 100 {
            history = Array(history.suffix(100))
        }

        if let encoded = try? JSONEncoder().encode(history) {
            userDefaults.set(encoded, forKey: feedbackHistoryKey)
        }
    }

    private func loadFeedbackHistory() -> [FeedbackHistoryItem] {
        guard let data = userDefaults.data(forKey: feedbackHistoryKey),
              let history = try? JSONDecoder().decode([FeedbackHistoryItem].self, from: data) else {
            return []
        }
        return history
    }

    // MARK: - Statistics

    /// Get feedback statistics for display
    func getStatistics() -> RewardStatistics {
        let history = loadFeedbackHistory()

        // Calculate feedback rate (submissions per day)
        var submissionsPerDay: Double = 0
        if history.count >= 2,
           let firstDate = history.first?.date,
           let lastDate = history.last?.date {
            let daysDiff = Calendar.current.dateComponents([.day], from: firstDate, to: lastDate).day ?? 1
            if daysDiff > 0 {
                submissionsPerDay = Double(history.count) / Double(daysDiff)
            }
        }

        return RewardStatistics(
            totalFeedback: totalFeedbackCount,
            earnedMonths: earnedMonths,
            currentProgress: currentMonthProgress,
            progressPercentage: progressPercentage,
            cardsRemaining: cardsRemaining,
            lastSubmissionDate: lastFeedbackDate,
            submissionsPerDay: submissionsPerDay
        )
    }

    // MARK: - Reset (for testing)

    /// Resets all reward progress (use only for testing)
    func resetProgress() {
        totalFeedbackCount = 0
        earnedMonths = 0
        currentMonthProgress = 0
        lastFeedbackDate = nil
        userDefaults.removeObject(forKey: feedbackHistoryKey)
        Logger.warning("Reward progress reset", category: .app)
    }
}

// MARK: - Models

struct RewardStatistics {
    let totalFeedback: Int
    let earnedMonths: Int
    let currentProgress: Int
    let progressPercentage: Double
    let cardsRemaining: Int
    let lastSubmissionDate: Date?
    let submissionsPerDay: Double
}
