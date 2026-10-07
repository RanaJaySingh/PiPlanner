import Foundation
import Observation

/// Screen 16: moves saved money between two goals. The standing split is unchanged.
@MainActor
@Observable
final class TransferViewModel {
    var fromGoalID: Goal.ID?
    var toGoalID: Goal.ID?
    var amount: Decimal
    private let store: LedgerStore

    static let quickAmounts: [Decimal] = [1_000, 5_000, 10_000]

    init(store: LedgerStore, request: TransferRequest) {
        self.store = store
        // Defaults (mockup 16): into the goal furthest behind, out of the best-funded other goal.
        let goals = store.ledger.activeGoals
        let shortfall = { (goal: Goal) -> Decimal in
            if case let .behind(amount) = store.progress(of: goal.id)?.status { return amount }
            return 0
        }
        let to = request.toGoalID
            ?? goals.filter { $0.id != request.fromGoalID }.max { shortfall($0) < shortfall($1) }?.id
        let from = request.fromGoalID
            ?? goals.filter { $0.id != to }.max { store.ledger.saved($0.id) < store.ledger.saved($1.id) }?.id
        fromGoalID = from
        toGoalID = to
        amount = request.amount
    }

    var goals: [Goal] { store.ledger.activeGoals }
    var fromGoal: Goal? { fromGoalID.flatMap(store.ledger.goal) }
    var toGoal: Goal? { toGoalID.flatMap(store.ledger.goal) }

    func saved(_ goalID: Goal.ID?) -> Decimal {
        goalID.map(store.ledger.saved) ?? 0
    }

    func chooseFrom(_ id: Goal.ID) {
        if id == toGoalID { toGoalID = fromGoalID }
        fromGoalID = id
    }

    func chooseTo(_ id: Goal.ID) {
        if id == fromGoalID { fromGoalID = toGoalID }
        toGoalID = id
    }

    /// 16b: "Emergency has only ₹55,000 saved."
    var errorMessage: String? {
        guard let fromGoal, amount > saved(fromGoal.id) else { return nil }
        return String(localized: "\(fromGoal.name) has only \(MoneyFormat.rupees(saved(fromGoal.id))) saved.")
    }

    var canConfirm: Bool {
        guard let fromGoalID, let toGoalID else { return false }
        return fromGoalID != toGoalID && amount > 0 && errorMessage == nil
    }

    func confirm() throws {
        guard let fromGoalID, let toGoalID else { return }
        try store.transfer(from: fromGoalID, to: toGoalID, amount: amount)
    }
}
