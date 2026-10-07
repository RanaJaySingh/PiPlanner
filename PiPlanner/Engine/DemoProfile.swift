import Foundation

/// Rahul's demo profile from the hackathon plan. Reset demo restores it.
enum DemoProfile {
    static let customerName = "Rahul"
    static let openingSavings: Decimal = 100_000
    static let spendingBalance: Decimal = 72_000

    static func makeAccounts() -> [Account] {
        [
            Account(
                id: UUID(),
                bank: "HDFC",
                kind: String(localized: "Savings"),
                maskedNumber: "••4821",
                role: .dedicatedSavings,
                mockBalance: openingSavings,
                linkedInPaytm: true
            ),
            Account(
                id: UUID(),
                bank: "SBI",
                kind: String(localized: "Spending"),
                maskedNumber: "••7730",
                role: .spending,
                mockBalance: spendingBalance,
                linkedInPaytm: false
            ),
        ]
    }

    static func makeLedger() -> Ledger {
        Ledger(accounts: makeAccounts())
    }

    /// "A ₹10 lakh car by Sep 2030 and a ₹2 lakh emergency fund in a year", starting `start`.
    static func goalDrafts(start: YearMonth) -> [GoalDraft] {
        [
            GoalDraft(name: "Car", target: 1_000_000, start: start, end: start.adding(months: 47), standingPercent: 60),
            GoalDraft(name: "Emergency", target: 200_000, start: start, end: start.adding(months: 11), standingPercent: 40),
        ]
    }

    /// "Add a ₹50,000 vacation by March".
    static func vacationDraft(start: YearMonth) -> GoalDraft {
        GoalDraft(name: "Vacation", target: 50_000, start: start, end: start.adding(months: 1).next(month: 3))
    }
}
