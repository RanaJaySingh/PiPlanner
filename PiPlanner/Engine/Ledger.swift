import Foundation

/// The dedicated-savings ledger. A value type: every rule is a `mutating` method that validates first,
/// so a thrown error leaves the ledger unchanged.
///
/// Current saving of a goal is never stored. It is the sum of its slices on saved entries,
/// so History cannot drift from the totals.
struct Ledger: Hashable, Codable, Sendable {
    /// Where a new goal is being created from; this decides its starting standing share.
    enum GoalPlacement: Hashable, Sendable {
        case standalone
        case onOpenEntry
        case onDeletion(of: UUID)
    }

    enum BalanceChange: Hashable, Sendable {
        case unchanged
        case increased(by: Decimal)
        case decreased(by: Decimal)
    }

    var accounts: [Account]
    private(set) var consent: Consent?
    private(set) var goals: [Goal] = []
    /// The last balance of the dedicated account, used to find what is new.
    private(set) var snapshot: Decimal?
    /// Oldest first.
    private(set) var history: [HistoryEntry] = []

    init(accounts: [Account]) {
        self.accounts = accounts
    }

    // MARK: - Accounts and consent

    /// Marks one account as dedicated savings; every other account becomes spending.
    mutating func markDedicated(_ accountID: UUID?) {
        for index in accounts.indices {
            accounts[index].role = accounts[index].id == accountID ? .dedicatedSavings : .spending
        }
    }

    mutating func setLinkedInPaytm(_ isLinked: Bool, accountID: UUID) {
        guard let index = accounts.firstIndex(where: { $0.id == accountID }) else { return }
        accounts[index].linkedInPaytm = isLinked
    }

    mutating func setConsent(isOn: Bool) throws {
        guard let account = dedicatedAccount else { throw LedgerError.noDedicatedAccount }
        consent = Consent(isOn: isOn, acceptedScope: "balance:\(account.id.uuidString)")
    }

    // MARK: - Setup

    /// Locks the opening split: creates the goals, stores the snapshot and writes the saved opening entry.
    mutating func completeSetup(
        goals drafts: [GoalDraft],
        openingBalance: Decimal,
        source: HistoryEntry.Source,
        date: Date
    ) throws {
        guard history.isEmpty else { throw LedgerError.setupAlreadyComplete }
        guard dedicatedAccount != nil else { throw LedgerError.noDedicatedAccount }
        guard !drafts.isEmpty else { throw LedgerError.noGoals }
        guard openingBalance >= 0 else { throw LedgerError.nonPositiveAmount }
        if let issue = drafts.lazy.flatMap(\.issues).first { throw LedgerError.invalidGoal(issue) }

        let split = drafts.count == 1
            ? Split.equal([drafts[0].id])
            : Split(drafts.map { Split.Share(goalID: $0.id, percent: $0.standingPercent) })
        guard split.isComplete else { throw LedgerError.splitIncomplete }

        goals = drafts.map { Goal(draft: $0, standingPercent: split[$0.id]) }
        snapshot = openingBalance
        history.append(HistoryEntry(
            kind: .opening,
            source: source,
            date: date,
            previousBalance: 0,
            fetchedBalance: source == .typed ? nil : openingBalance,
            amount: openingBalance,
            state: .saved,
            split: split,
            slices: split.allocate(openingBalance)
        ))
    }

    // MARK: - New amounts

    /// Compares a fetched balance with the snapshot. Unchanged writes nothing; lower goes to withdrawal.
    func balanceChange(forFetched fetched: Decimal) throws -> BalanceChange {
        guard let snapshot else { throw LedgerError.setupIncomplete }
        if fetched == snapshot { return .unchanged }
        return fetched > snapshot ? .increased(by: fetched - snapshot) : .decreased(by: snapshot - fetched)
    }

    /// Writes an open credit entry with the suggested split. Pending goal edits apply first.
    @discardableResult
    mutating func beginCredit(
        amount: Decimal,
        source: HistoryEntry.Source,
        fetchedBalance: Decimal?,
        date: Date
    ) throws -> HistoryEntry.ID {
        guard let snapshot else { throw LedgerError.setupIncomplete }
        guard openEntry == nil else { throw LedgerError.entryAlreadyOpen }
        guard amount > 0 else { throw LedgerError.nonPositiveAmount }

        applyPendingEdits()
        let split = standingSplit
        let entry = HistoryEntry(
            kind: .credit,
            source: source,
            date: date,
            previousBalance: snapshot,
            fetchedBalance: fetchedBalance,
            amount: amount,
            state: .open,
            split: split,
            slices: split.allocate(amount)
        )
        history.append(entry)
        return entry.id
    }

    /// The one-time percentage change for this amount only.
    mutating func changeSplit(ofEntry entryID: HistoryEntry.ID, to split: Split, carryForward: Bool) throws {
        let index = try openEntryIndex(entryID)
        guard !history[index].customSplit else { throw LedgerError.splitAlreadyChanged }
        try validate(split, within: Set(activeGoalIDs))

        history[index].split = split
        history[index].slices = split.allocate(history[index].amount)
        history[index].customSplit = true
        history[index].carriesSplitForward = carryForward
    }

    /// Freezes the entry. Goal totals change now; the snapshot moves to the new balance.
    mutating func saveEntry(_ entryID: HistoryEntry.ID) throws {
        let index = try openEntryIndex(entryID)
        history[index].state = .saved
        snapshot = history[index].newBalance
        if history[index].customSplit, history[index].carriesSplitForward {
            setStanding(history[index].split.normalised())
        }
    }

    // MARK: - Goals

    /// Adds a goal at ₹0 saved. Outside an entry it takes its share from the others proportionally.
    @discardableResult
    mutating func createGoal(_ draft: GoalDraft, placement: GoalPlacement) throws -> Goal.ID {
        guard hasCompletedSetup else { throw LedgerError.setupIncomplete }
        if let issue = draft.issues.first { throw LedgerError.invalidGoal(issue) }

        var goal = Goal(draft: draft, standingPercent: 0)
        switch placement {
        case .standalone:
            if activeGoals.isEmpty {
                goal.standingPercent = 100
            } else {
                let share = min(max(draft.standingPercent, 0), 100)
                goal.standingPercent = share
                scaleStanding(of: activeGoalIDs, toTotal: 100 - share)
            }
        case .onOpenEntry:
            guard openEntry != nil else { throw LedgerError.entryNotOpen }
            goal.standingPercent = activeGoals.isEmpty ? 100 : 0
        case let .onDeletion(deletingID):
            guard activeGoalIDs.contains(deletingID) else { throw LedgerError.goalNotFound }
        }
        goals.append(goal)
        return goal.id
    }

    /// Replaces the standing split. It only suggests the split of the next new amount.
    mutating func updateStandingSplit(_ split: Split) throws {
        guard Set(split.goalIDs) == Set(activeGoalIDs) else { throw LedgerError.splitHasUnknownGoal }
        guard split.isComplete else { throw LedgerError.splitIncomplete }
        setStanding(split)
    }

    /// Holds an edit on the goal until the next entry is written. No earlier entry is rewritten.
    mutating func stageEdit(_ edit: GoalEdit, for goalID: Goal.ID) throws {
        guard let index = goals.firstIndex(where: { $0.id == goalID && !$0.isDeleted }) else {
            throw LedgerError.goalNotFound
        }
        let draft = GoalDraft(
            id: goalID, name: edit.name, target: edit.target, start: edit.start,
            end: edit.end, standingPercent: edit.standingPercent
        )
        if let issue = draft.issues.first { throw LedgerError.invalidGoal(issue) }
        goals[index].pendingEdit = draft.edit
    }

    // MARK: - Transfer

    /// Moves saved money between two goals as its own entry. Standing percentages are unchanged.
    mutating func transfer(from fromID: Goal.ID, to toID: Goal.ID, amount: Decimal, date: Date) throws {
        guard fromID != toID else { throw LedgerError.sameGoal }
        let active = Set(activeGoalIDs)
        guard active.contains(fromID), active.contains(toID) else { throw LedgerError.goalNotFound }
        guard amount > 0 else { throw LedgerError.nonPositiveAmount }
        guard amount <= saved(fromID) else { throw LedgerError.insufficientSavings }

        applyPendingEdits()
        history.append(HistoryEntry(
            kind: .transfer,
            source: nil,
            date: date,
            previousBalance: snapshot ?? 0,
            fetchedBalance: nil,
            amount: amount,
            state: .saved,
            split: Split(),
            slices: [Slice(goalID: fromID, amount: -amount), Slice(goalID: toID, amount: amount)],
            transfer: HistoryEntry.Transfer(fromGoalID: fromID, toGoalID: toID)
        ))
    }

    // MARK: - Delete

    /// The delete screen opens on an equal split of the released amount across the remaining goals.
    func deletionProposal(for goalID: Goal.ID) -> Split {
        .equal(activeGoalIDs.filter { $0 != goalID })
    }

    /// Writes one entry moving the released saving, removes the goal, and renormalises the standing split.
    mutating func deleteGoal(_ goalID: Goal.ID, redistribution split: Split, date: Date) throws {
        guard let index = goals.firstIndex(where: { $0.id == goalID && !$0.isDeleted }) else {
            throw LedgerError.goalNotFound
        }
        let receivers = Set(activeGoalIDs.filter { $0 != goalID })
        guard !receivers.isEmpty else { throw LedgerError.lastGoalNeedsReceiver }
        try validate(split, within: receivers)

        applyPendingEdits()
        let released = saved(goalID)
        history.append(HistoryEntry(
            kind: .goalDeleted,
            source: nil,
            date: date,
            previousBalance: snapshot ?? 0,
            fetchedBalance: nil,
            amount: released,
            state: .saved,
            split: split,
            slices: [Slice(goalID: goalID, amount: -released)] + split.allocate(released),
            deletedGoalID: goalID
        ))

        goals[index].isDeleted = true
        goals[index].standingPercent = 0
        goals[index].pendingEdit = nil
        setStanding(standingSplit.normalised())
        removeDeletedGoalFromOpenEntry(goalID)
    }

    // MARK: - Withdrawal

    /// Proposed reduction in proportion to each goal's saving.
    func withdrawalProposal() -> Split {
        .proportional(to: activeGoals.map { ($0.id, saved($0.id)) })
    }

    /// Checks a withdrawal: reductions equal the shortfall and no goal goes below ₹0.
    func validateWithdrawal(amount: Decimal, split: Split) throws {
        guard amount > 0 else { throw LedgerError.nonPositiveAmount }
        guard amount <= assignedTotal else { throw LedgerError.withdrawalExceedsSavings }
        try validate(split, within: Set(activeGoalIDs))
        for slice in split.allocate(-amount) where -slice.amount > saved(slice.goalID) {
            throw LedgerError.reductionExceedsSaving
        }
    }

    mutating func recordWithdrawal(
        amount: Decimal,
        split: Split,
        source: HistoryEntry.Source,
        fetchedBalance: Decimal?,
        date: Date
    ) throws {
        guard let snapshot else { throw LedgerError.setupIncomplete }
        guard openEntry == nil else { throw LedgerError.entryAlreadyOpen }
        try validateWithdrawal(amount: amount, split: split)

        applyPendingEdits()
        let entry = HistoryEntry(
            kind: .withdrawal,
            source: source,
            date: date,
            previousBalance: snapshot,
            fetchedBalance: fetchedBalance,
            amount: amount,
            state: .saved,
            split: split,
            slices: split.allocate(-amount)
        )
        history.append(entry)
        self.snapshot = entry.newBalance
    }

    // MARK: - Private helpers

    private func openEntryIndex(_ entryID: HistoryEntry.ID) throws -> Int {
        guard let index = history.firstIndex(where: { $0.id == entryID }), history[index].isOpen else {
            throw LedgerError.entryNotOpen
        }
        return index
    }

    private func validate(_ split: Split, within allowed: Set<UUID>) throws {
        guard Set(split.goalIDs).isSubset(of: allowed) else { throw LedgerError.splitHasUnknownGoal }
        guard split.isComplete else { throw LedgerError.splitIncomplete }
    }

    private mutating func setStanding(_ split: Split) {
        for index in goals.indices where !goals[index].isDeleted {
            goals[index].standingPercent = split[goals[index].id]
        }
    }

    /// Scales the standing shares of `ids` so they add to `target`, keeping their proportions.
    private mutating func scaleStanding(of ids: [UUID], toTotal target: Decimal) {
        let current = ids.map { id in goals.first { $0.id == id }?.standingPercent ?? 0 }
        let weights = current.reduce(0, +) > 0 ? current : current.map { _ in 1 }
        let parts = Apportion.largestRemainder(total: max(target, 0), weights: weights, unit: 1 / 100)
        for (id, part) in zip(ids, parts) {
            if let index = goals.firstIndex(where: { $0.id == id }) {
                goals[index].standingPercent = part
            }
        }
    }

    /// Applies every held edit. Edited standing shares are kept; the others make room proportionally.
    private mutating func applyPendingEdits() {
        var editedShares = Set<UUID>()
        for index in goals.indices {
            guard let edit = goals[index].pendingEdit else { continue }
            if edit.standingPercent != goals[index].standingPercent {
                editedShares.insert(goals[index].id)
            }
            goals[index].apply(edit)
            goals[index].pendingEdit = nil
        }
        guard !editedShares.isEmpty else { return }

        let flexible = activeGoalIDs.filter { !editedShares.contains($0) }
        let fixedTotal = activeGoals.filter { editedShares.contains($0.id) }.reduce(0) { $0 + $1.standingPercent }
        if flexible.isEmpty || fixedTotal > 100 {
            setStanding(standingSplit.normalised())
        } else {
            scaleStanding(of: flexible, toTotal: 100 - fixedTotal)
        }
    }

    private mutating func removeDeletedGoalFromOpenEntry(_ goalID: UUID) {
        guard let index = history.firstIndex(where: \.isOpen), history[index].split.contains(goalID) else { return }
        var split = history[index].split
        split.remove(goalID)
        split = split.isEmpty ? .equal(activeGoalIDs) : split.normalised()
        history[index].split = split
        history[index].slices = split.allocate(history[index].amount)
    }
}
