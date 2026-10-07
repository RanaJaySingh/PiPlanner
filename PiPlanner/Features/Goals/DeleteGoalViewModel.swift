import Foundation
import Observation

/// Screen 17: where a deleted goal's saving goes. Starts equal; a goal created here resets it to equal.
@MainActor
@Observable
final class DeleteGoalViewModel {
    let goalID: Goal.ID
    var split: Split
    private(set) var isEdited = false
    private let store: LedgerStore
    private var receiverIDs: [UUID]

    init(store: LedgerStore, goalID: Goal.ID) {
        self.store = store
        self.goalID = goalID
        let proposal = store.ledger.deletionProposal(for: goalID)
        split = proposal
        receiverIDs = proposal.goalIDs
    }

    var goalName: String { LedgerText.goalName(goalID, in: store.ledger) }
    var released: Decimal { store.ledger.saved(goalID) }
    var hasReceivers: Bool { !split.isEmpty }
    var ledger: Ledger { store.ledger }

    func setPercent(_ percent: Decimal, for id: UUID) {
        split[id] = percent
        isEdited = true
    }

    func amount(for id: UUID) -> Decimal {
        split.amount(for: id, of: released)
    }

    /// Goals created on this screen join as receivers, and the split starts equal again (17d).
    func goalsChanged() {
        let receivers = store.ledger.activeGoalIDs.filter { $0 != goalID }
        guard receivers != receiverIDs else { return }
        receiverIDs = receivers
        split = store.ledger.deletionProposal(for: goalID)
        isEdited = false
    }

    /// "Car 62.5% · Emergency 37.5%"
    var standingAfterDeletion: String? {
        guard split.isComplete, let standing = store.standingSplitAfterDeleting(goalID, redistribution: split) else { return nil }
        return standing.shares
            .map { "\(LedgerText.goalName($0.goalID, in: store.ledger)) \(PercentFormat.percent($0.percent))" }
            .joined(separator: " · ")
    }

    var canDelete: Bool { hasReceivers && split.isComplete }

    func delete() throws {
        try store.deleteGoal(goalID, redistribution: split)
    }
}
