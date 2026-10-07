import Foundation

/// Where the customer is typing. It changes what a goal sentence means.
enum GrokSurface: String, Codable, Sendable {
    /// Setup Goal chat: sentences become the first goals.
    case goalSetup = "goal_setup"
    /// Ask tab: questions, transfers, new goals, or a split for the open entry.
    case ask
}

/// The only data Grok receives. Goal names, percentages, amounts, dates and status.
/// Never an account number, UPI id, phone, payee or statement line.
struct GrokContext: Codable, Hashable, Sendable {
    struct GoalSummary: Codable, Hashable, Sendable {
        let name: String
        let saved: Decimal
        let target: Decimal
        let requiredMonthly: Decimal
        let standingPercent: Decimal
        let start: String
        let end: String
        let status: String
    }

    let today: String
    let goals: [GoalSummary]
    /// The new amount on the open History entry, if any.
    let openEntryAmount: Decimal?
    /// The balance waiting to be split during setup.
    let readyToSplit: Decimal?
}

struct GrokRequest: Codable, Hashable, Sendable {
    let utterance: String
    let surface: GrokSurface
    let context: GrokContext
    /// How many follow-up questions were already asked in this thread.
    let followUpCount: Int
}

/// Structured JSON Grok returns. The engine validates every field before the customer sees it.
struct GrokReply: Codable, Hashable, Sendable {
    enum Kind: String, Codable, Sendable {
        case goals
        case entryGoal = "entry_goal"
        case transfer
        case answer
        case followUp = "follow_up"
        case unsupported
    }

    struct GoalPayload: Codable, Hashable, Sendable {
        var name: String
        var target: Decimal
        /// "YYYY-MM"
        var end: String
        var start: String?
        var percent: Decimal?
    }

    struct SharePayload: Codable, Hashable, Sendable {
        var goal: String
        var percent: Decimal
    }

    struct TransferPayload: Codable, Hashable, Sendable {
        var from: String
        var to: String
        var amount: Decimal
    }

    var kind: Kind
    var goals: [GoalPayload]?
    var entrySplit: [SharePayload]?
    var transfer: TransferPayload?
    var message: String?

    enum CodingKeys: String, CodingKey {
        case kind, goals, transfer, message
        case entrySplit = "entry_split"
    }
}

extension YearMonth {
    /// "2030-09"
    var isoString: String { String(format: "%04d-%02d", year, month) }

    init?(isoString: String) {
        let parts = isoString.split(separator: "-")
        guard parts.count == 2, let year = Int(parts[0]), let month = Int(parts[1]), (1...12).contains(month) else {
            return nil
        }
        self.init(year: year, month: month)
    }
}
