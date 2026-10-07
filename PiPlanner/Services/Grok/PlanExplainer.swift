import Foundation

/// Plain-language explanations built only from engine numbers. Used by the mock client and as the
/// fallback whenever a live answer quotes a rupee figure the engine did not produce.
enum PlanExplainer {
    static func splitAnswer(context: GrokContext) -> String {
        guard !context.goals.isEmpty else { return noGoalsAnswer }
        let parts = context.goals.map { "\($0.name) \(PercentFormat.percent($0.standingPercent))" }
        return "Your next new amount is suggested as \(parts.joined(separator: ", ")). "
            + "You can change it once on each History entry, or set a new standing split in Goals."
    }

    static func summaryAnswer(context: GrokContext) -> String {
        guard !context.goals.isEmpty else { return noGoalsAnswer }
        let lines = context.goals.map { goal in
            "\(goal.name) has \(MoneyFormat.rupees(goal.saved)) of \(MoneyFormat.rupees(goal.target)) "
                + "and needs \(MoneyFormat.rupees(goal.requiredMonthly)) a month"
        }
        return lines.joined(separator: ". ") + "."
    }

    /// 13c: "₹1,00,000 was already assigned. This ₹50,000 is new. Car gets ₹4,583 less than it needs."
    static func creditExplanation(assigned: Decimal, amount: Decimal, shortfalls: [(name: String, amount: Decimal)]) -> String {
        var text = "\(MoneyFormat.rupees(assigned)) was already assigned. This \(MoneyFormat.rupees(amount)) is new."
        if shortfalls.isEmpty {
            text += " Every goal gets what it needs this month."
        } else {
            for shortfall in shortfalls {
                text += " \(shortfall.name) gets \(MoneyFormat.rupees(shortfall.amount)) less than it needs."
            }
        }
        return text
    }

    /// Every rupee figure the context allows an answer to quote.
    static func allowedAmounts(in context: GrokContext) -> Set<Decimal> {
        var amounts: Set<Decimal> = []
        for goal in context.goals {
            amounts.formUnion([goal.saved, goal.target, goal.requiredMonthly])
        }
        if let open = context.openEntryAmount { amounts.insert(open) }
        if let ready = context.readyToSplit { amounts.insert(ready) }
        amounts.insert(context.goals.reduce(0) { $0 + $1.saved })
        return amounts
    }

    /// Every "₹…" figure quoted in `text`.
    static func quotedAmounts(in text: String) -> [Decimal] {
        guard let regex = try? NSRegularExpression(pattern: #"₹\s*([\d,]+(?:\.\d+)?)"#) else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        return regex.matches(in: text, range: range).compactMap { match in
            Range(match.range(at: 1), in: text).flatMap {
                Decimal(string: text[$0].replacingOccurrences(of: ",", with: ""), locale: Locale(identifier: "en_US_POSIX"))
            }
        }
    }

    private static let noGoalsAnswer = "You have no goals yet. Tell me what you are saving for and by when."
}
