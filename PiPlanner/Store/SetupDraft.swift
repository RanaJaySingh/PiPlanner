import Foundation

/// Everything collected during first-time setup before the opening split is locked.
struct SetupDraft: Hashable {
    var openingBalance: Decimal = 0
    var balanceSource: HistoryEntry.Source = .typed
    var goals: [GoalDraft] = []
    var chat = ChatThread()

    /// Percentages over the drafted goals; a single goal always gets 100%.
    var splitTotal: Decimal {
        goals.count == 1 ? 100 : goals.reduce(0) { $0 + $1.standingPercent }
    }

    var isSplitComplete: Bool {
        !goals.isEmpty && splitTotal == 100
    }

    mutating func upsert(_ draft: GoalDraft) {
        if let index = goals.firstIndex(where: { $0.id == draft.id }) {
            goals[index] = draft
        } else {
            goals.append(draft)
        }
    }

    /// The opening amount for one draft at its current percentage.
    func amount(for draftID: GoalDraft.ID) -> Decimal {
        currentSplit.amount(for: draftID, of: openingBalance)
    }

    var currentSplit: Split {
        goals.count == 1
            ? .equal(goals.map(\.id))
            : Split(goals.map { Split.Share(goalID: $0.id, percent: $0.standingPercent) })
    }
}
