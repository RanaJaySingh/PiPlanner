import Foundation

/// A calendar month. Goal dates are months, and "this month" drives the on-track check.
struct YearMonth: Hashable, Comparable, Codable, Sendable {
    let year: Int
    let month: Int

    init(year: Int, month: Int) {
        precondition((1...12).contains(month), "month must be in 1...12")
        self.year = year
        self.month = month
    }

    init(date: Date, calendar: Calendar) {
        let components = calendar.dateComponents([.year, .month], from: date)
        self.init(year: components.year ?? 1970, month: components.month ?? 1)
    }

    private init(ordinal: Int) {
        year = ordinal / 12
        month = ordinal % 12 + 1
    }

    private var ordinal: Int { year * 12 + month - 1 }

    func adding(months: Int) -> YearMonth {
        YearMonth(ordinal: ordinal + months)
    }

    /// Months from `self` through `end`, counting both ends. Oct 2026 through Sep 2030 is 48.
    func monthsInclusive(through end: YearMonth) -> Int {
        max(0, end.ordinal - ordinal + 1)
    }

    /// The next occurrence of `month` on or after `self`.
    func next(month target: Int) -> YearMonth {
        let offset = (target - month + 12) % 12
        return adding(months: offset)
    }

    func contains(_ date: Date, calendar: Calendar) -> Bool {
        YearMonth(date: date, calendar: calendar) == self
    }

    static func < (lhs: YearMonth, rhs: YearMonth) -> Bool {
        lhs.ordinal < rhs.ordinal
    }
}
