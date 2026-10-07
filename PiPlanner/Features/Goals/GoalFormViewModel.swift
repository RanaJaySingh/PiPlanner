import Foundation
import Observation

/// Screen 6 in every mode: create in setup, create from Goals or Ask, create on an entry or a deletion, or edit.
@MainActor
@Observable
final class GoalFormViewModel {
    enum ShareSection: Equatable {
        /// Hidden: the share comes from an entry, a deletion or the setup split.
        case hidden
        /// "Only goal, so it gets 100%."
        case onlyGoal
        /// Editable share of new credits.
        case editable
    }

    let request: GoalFormRequest
    var draft: GoalDraft
    private let store: LedgerStore

    /// New goals from the Goals tab start with this share; the others make room proportionally.
    static let defaultStandaloneShare: Decimal = 20
    static let maximumYears = 30

    init(store: LedgerStore, request: GoalFormRequest) {
        self.store = store
        self.request = request

        let month = store.currentMonth
        if case let .edit(goalID) = request.mode, let goal = store.ledger.goal(goalID) {
            draft = request.draft ?? GoalDraft(goal: goal)
        } else {
            draft = request.draft ?? GoalDraft(name: "", target: 0, start: month, end: month.adding(months: 11))
        }
        if case .standalone = request.mode, request.draft?.standingPercent ?? 0 == 0 {
            draft.standingPercent = store.ledger.activeGoals.isEmpty ? 100 : Self.defaultStandaloneShare
        }
    }

    // MARK: - Presentation

    var isEditing: Bool {
        if case .edit = request.mode { return true }
        return false
    }

    var isNewSetupGoal: Bool {
        request.mode == .setup && !store.setup.goals.contains { $0.id == draft.id }
    }

    var shareSection: ShareSection {
        switch request.mode {
        case .setup:
            let others = store.setup.goals.filter { $0.id != draft.id }
            return others.isEmpty ? .onlyGoal : .hidden
        case .standalone:
            return store.ledger.activeGoals.isEmpty ? .onlyGoal : .editable
        case .edit:
            return store.ledger.activeGoals.count == 1 ? .onlyGoal : .editable
        case .onEntry, .onDeletion:
            return .hidden
        }
    }

    var showsSavedSoFar: Bool {
        switch request.mode {
        case .setup, .standalone, .edit: true
        case .onEntry, .onDeletion: false
        }
    }

    var savedSoFar: Decimal {
        if case let .edit(goalID) = request.mode { return store.ledger.saved(goalID) }
        return 0
    }

    var requiredMonthly: Decimal {
        let months = GoalMath.monthsRemaining(start: draft.start, end: draft.end, asOf: store.currentMonth)
        return GoalMath.requiredMonthly(target: draft.target, saved: savedSoFar, monthsRemaining: months)
    }

    /// "₹7,500 of every ₹50,000 credit"
    var shareExample: String {
        let reference = store.referenceCreditAmount
        let part = (reference * draft.standingPercent / 100).rounded()
        return String(localized: "\(MoneyFormat.rupees(part)) of every \(MoneyFormat.rupees(reference)) credit")
    }

    var startRange: ClosedRange<YearMonth> {
        let month = store.currentMonth
        return month.adding(months: -120)...month.adding(months: Self.maximumYears * 12)
    }

    var endRange: ClosedRange<YearMonth> {
        draft.start.adding(months: 1)...store.currentMonth.adding(months: Self.maximumYears * 12)
    }

    var canSave: Bool {
        draft.isValid && (shareSection != .editable || (0...100).contains(draft.standingPercent))
    }

    var issueMessage: String? {
        guard draft.end <= draft.start else { return nil }
        return String(localized: "The end date must be after the start date.")
    }

    // MARK: - Save

    enum SaveResult {
        case saved
        /// Two or more goals now: reopen the standing split (15).
        case savedNeedsStandingSplit
    }

    func save() throws -> SaveResult {
        switch request.mode {
        case .setup:
            var saved = draft
            if shareSection == .onlyGoal { saved.standingPercent = 100 }
            if isNewSetupGoal, !store.setup.goals.isEmpty {
                store.setup.goals = GrokOrchestrator.suggestedSplit(for: store.setup.goals + [saved], asOf: store.currentMonth)
            } else {
                store.setup.upsert(saved)
            }
            return .saved
        case .standalone:
            try store.createGoal(draft, placement: .standalone)
            return store.ledger.activeGoals.count >= 2 ? .savedNeedsStandingSplit : .saved
        case .onEntry:
            try store.createGoal(draft, placement: .onOpenEntry)
            return .saved
        case let .onDeletion(goalID):
            try store.createGoal(draft, placement: .onDeletion(of: goalID))
            return .saved
        case let .edit(goalID):
            var edited = draft
            if shareSection == .onlyGoal { edited.standingPercent = 100 }
            try store.stageEdit(edited, for: goalID)
            return .saved
        }
    }
}
