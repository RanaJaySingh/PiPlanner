import Foundation

/// Goal formulas. These live in Swift and never in Grok.
enum GoalMath {
    /// required savings = (target − current saving) / months remaining
    static func requiredMonthly(target: Decimal, saved: Decimal, monthsRemaining: Int) -> Decimal {
        guard monthsRemaining > 0 else { return 0 }
        return max(0, (target - saved) / Decimal(monthsRemaining)).rounded()
    }

    /// Months left including the current one; before the start date, the whole span.
    static func monthsRemaining(start: YearMonth, end: YearMonth, asOf month: YearMonth) -> Int {
        max(month, start).monthsInclusive(through: end)
    }
}
