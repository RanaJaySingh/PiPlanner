import Foundation

enum GoalStatus: Hashable, Sendable {
    case onTrack
    case behind(by: Decimal)
    case ended
}

struct GoalProgress: Hashable, Sendable {
    let saved: Decimal
    let target: Decimal
    let requiredMonthly: Decimal
    let monthsRemaining: Int
    let status: GoalStatus

    var fractionComplete: Double {
        guard target > 0 else { return 0 }
        return min(1, max(0, (saved / target).doubleValue))
    }
}

extension Ledger {
    /// Saved amount, target, required savings and status as of `month`.
    ///
    /// A goal is behind when this month's credits gave it less than it needed at the start of the month.
    /// Before any credit this month that included the goal, it is on track.
    func progress(of goalID: UUID, asOf month: YearMonth, calendar: Calendar) -> GoalProgress? {
        guard let goal = goal(goalID) else { return nil }
        let saved = saved(goalID)
        let months = GoalMath.monthsRemaining(start: goal.start, end: goal.end, asOf: month)
        let required = GoalMath.requiredMonthly(target: goal.target, saved: saved, monthsRemaining: months)

        let status: GoalStatus
        if months == 0 {
            status = .ended
        } else if let shortfall = monthShortfall(of: goal, asOf: month, calendar: calendar, adding: 0, includeEvenIfNoCredit: false) {
            status = shortfall > 0 ? .behind(by: shortfall) : .onTrack
        } else {
            status = .onTrack
        }

        return GoalProgress(saved: saved, target: goal.target, requiredMonthly: required, monthsRemaining: months, status: status)
    }

    /// How much less than needed each goal would get this month if `entry` were saved with `split`.
    /// Only positive shortfalls are returned. Used for "Car gets ₹4,583 less than it needs."
    func shortfalls(ifSaving entry: HistoryEntry, with split: Split, asOf month: YearMonth, calendar: Calendar) -> [UUID: Decimal] {
        var result: [UUID: Decimal] = [:]
        for slice in split.allocate(entry.amount) {
            guard let goal = goal(slice.goalID) else { continue }
            if let shortfall = monthShortfall(of: goal, asOf: month, calendar: calendar, adding: slice.amount, includeEvenIfNoCredit: true),
               shortfall > 0 {
                result[slice.goalID] = shortfall
            }
        }
        return result
    }

    /// Required-at-start-of-month minus this month's credits (plus `extra`). Nil when no credit this month included the goal.
    private func monthShortfall(
        of goal: Goal,
        asOf month: YearMonth,
        calendar: Calendar,
        adding extra: Decimal,
        includeEvenIfNoCredit: Bool
    ) -> Decimal? {
        let monthCredits = history.filter {
            $0.kind == .credit && $0.state == .saved && month.contains($0.date, calendar: calendar) && $0.split.contains(goal.id)
        }
        guard includeEvenIfNoCredit || !monthCredits.isEmpty else { return nil }

        let creditedThisMonth = monthCredits.reduce(0) { $0 + $1.slice(for: goal.id) }
        let savedAtMonthStart = saved(goal.id) - creditedThisMonth
        let months = GoalMath.monthsRemaining(start: goal.start, end: goal.end, asOf: month)
        let neededThisMonth = GoalMath.requiredMonthly(
            target: goal.target,
            saved: savedAtMonthStart,
            monthsRemaining: months
        )
        return neededThisMonth - creditedThisMonth - extra
    }
}
