import Foundation

extension Ledger {
    var dedicatedAccount: Account? {
        accounts.first { $0.role == .dedicatedSavings }
    }

    var hasCompletedSetup: Bool { !history.isEmpty }

    var activeGoals: [Goal] { goals.filter { !$0.isDeleted } }

    var activeGoalIDs: [UUID] { activeGoals.map(\.id) }

    func goal(_ id: UUID) -> Goal? {
        goals.first { $0.id == id }
    }

    func entry(_ id: HistoryEntry.ID) -> HistoryEntry? {
        history.first { $0.id == id }
    }

    /// At most one entry is open at a time.
    var openEntry: HistoryEntry? {
        history.first(where: \.isOpen)
    }

    var standingSplit: Split {
        Split(activeGoals.map { Split.Share(goalID: $0.id, percent: $0.standingPercent) })
    }

    /// Current saving: the sum of this goal's slices on saved entries.
    func saved(_ goalID: UUID) -> Decimal {
        history
            .filter { $0.state == .saved }
            .reduce(0) { $0 + $1.slice(for: goalID) }
    }

    /// Everything assigned across active goals. Equals the snapshot whenever no entry is open.
    var assignedTotal: Decimal {
        activeGoalIDs.reduce(0) { $0 + saved($1) }
    }

    /// Entries that moved money for this goal, newest first, with the goal's signed amount.
    func slices(for goalID: UUID) -> [(entry: HistoryEntry, amount: Decimal)] {
        history
            .filter { $0.state == .saved }
            .reversed()
            .compactMap { entry in
                let amount = entry.slice(for: goalID)
                return amount == 0 ? nil : (entry, amount)
            }
    }
}
