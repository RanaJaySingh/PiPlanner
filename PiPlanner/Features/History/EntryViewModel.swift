import Foundation
import Observation

/// Screen 13: an open entry with its one-time split, or a saved entry, read-only.
@MainActor
@Observable
final class EntryViewModel {
    let entryID: HistoryEntry.ID
    private let store: LedgerStore

    /// True once "Update percentages for this amount" is tapped, a goal is created here, or Grok fills the split.
    private(set) var isEditing = false
    var draft = Split()
    var carryForward = true
    private var knownGoalIDs: [UUID] = []

    init(store: LedgerStore, entryID: HistoryEntry.ID) {
        self.store = store
        self.entryID = entryID
        knownGoalIDs = store.ledger.activeGoalIDs
    }

    var ledger: Ledger { store.ledger }
    var entry: HistoryEntry? { store.ledger.entry(entryID) }
    var isOpen: Bool { entry?.isOpen == true }
    var activeGoals: [Goal] { store.ledger.activeGoals }
    var hasSingleGoal: Bool { activeGoals.count == 1 }

    // MARK: - Open entry

    /// Saved amounts shown in the grey "Already saved, not changing" block.
    var lockedRows: [(name: String, amount: Decimal)] {
        activeGoals.map { ($0.name, store.ledger.saved($0.id)) }
    }

    /// The split shown before any change: the entry's own suggestion.
    var suggestedRows: [(goalID: UUID, name: String, percent: Decimal, amount: Decimal)] {
        guard let entry else { return [] }
        let slices = entry.split.allocate(entry.amount)
        return entry.split.shares.map { share in
            let amount = slices.first { $0.goalID == share.goalID }?.amount ?? 0
            return (share.goalID, LedgerText.goalName(share.goalID, in: store.ledger), share.percent, amount)
        }
    }

    func beginEditing() {
        guard let entry, isOpen else { return }
        var split = Split()
        for goal in activeGoals {
            split[goal.id] = entry.split[goal.id]
        }
        draft = split
        isEditing = true
    }

    var draftTotal: Decimal { draft.total }

    func draftAmount(for goalID: UUID) -> Decimal {
        guard let entry else { return 0 }
        return draft.amount(for: goalID, of: entry.amount)
    }

    /// Goals that would get less than they need this month with the draft split.
    var draftShortfalls: [UUID: Decimal] {
        guard let entry, draft.isComplete else { return [:] }
        return store.ledger.shortfalls(ifSaving: entry, with: draft, asOf: store.currentMonth, calendar: store.calendar)
    }

    /// 13c: "₹1,00,000 was already assigned. This ₹50,000 is new. Car gets ₹4,583 less than it needs."
    var explanation: String? {
        guard let entry, isEditing, draft.isComplete else { return nil }
        let shortfalls = draftShortfalls
        let ordered = draft.goalIDs.compactMap { id in shortfalls[id].map { (LedgerText.goalName(id, in: store.ledger), $0) } }
        return PlanExplainer.creditExplanation(assigned: store.ledger.assignedTotal, amount: entry.amount, shortfalls: ordered)
    }

    var canSave: Bool {
        isOpen && (!isEditing || draft.isComplete)
    }

    /// Keeps the draft in step with goals created or deleted while the entry is open.
    func goalsChanged() {
        let current = store.ledger.activeGoalIDs
        let added = current.filter { !knownGoalIDs.contains($0) }
        knownGoalIDs = current
        guard isOpen else { return }

        if !added.isEmpty, !isEditing {
            beginEditing()
        }
        for id in draft.goalIDs where !current.contains(id) {
            draft.remove(id)
        }
        for id in added where !draft.contains(id) {
            draft[id] = max(0, 100 - draft.total)
        }
    }

    /// A split confirmed in the Ask tab arrives here, filled in but not saved.
    func applyProposedSplit() {
        guard isOpen, let split = store.proposedEntrySplit else { return }
        store.proposedEntrySplit = nil
        knownGoalIDs = store.ledger.activeGoalIDs
        var filled = Split()
        for goal in activeGoals {
            filled[goal.id] = split[goal.id]
        }
        draft = filled
        isEditing = true
    }

    func save() throws {
        guard let entry else { return }
        var custom: Split?
        if isEditing {
            let trimmed = Split(draft.shares.filter { $0.percent > 0 })
            custom = trimmed == entry.split ? nil : trimmed
        }
        try store.saveEntry(entryID, customSplit: custom, carryForward: carryForward)
        isEditing = false
    }

    // MARK: - Saved entry

    /// Rows for a saved split: "60% of ₹50,000" and "₹30,000".
    var savedRows: [(goalID: UUID, name: String, detail: String, amount: Decimal)] {
        guard let entry else { return [] }
        let basis = MoneyFormat.rupees(entry.amount)
        return entry.slices.compactMap { slice in
            guard slice.amount != 0 else { return nil }
            let name = LedgerText.goalName(slice.goalID, in: store.ledger)
            switch entry.kind {
            case .transfer:
                let detail = slice.amount < 0 ? String(localized: "Moved out") : String(localized: "Moved in")
                return (slice.goalID, name, detail, slice.amount)
            case .goalDeleted where slice.goalID == entry.deletedGoalID:
                return (slice.goalID, name, String(localized: "Released"), slice.amount)
            default:
                break
            }
            let percent = entry.split[slice.goalID]
            let detail = percent > 0 ? String(localized: "\(PercentFormat.percent(percent)) of \(basis)") : ""
            return (slice.goalID, name, detail, slice.amount)
        }
    }
}
