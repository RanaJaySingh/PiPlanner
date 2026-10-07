import Foundation
import Observation

/// Screen 18: which goals a lower balance comes from. Proposed in proportion to each goal's saving.
@MainActor
@Observable
final class WithdrawalViewModel {
    let request: WithdrawalRequest
    var split: Split
    private let store: LedgerStore

    init(store: LedgerStore, request: WithdrawalRequest) {
        self.store = store
        self.request = request
        split = store.ledger.withdrawalProposal()
    }

    var ledger: Ledger { store.ledger }

    func reduction(for goalID: UUID) -> Decimal {
        split.amount(for: goalID, of: -request.amount)
    }

    /// Nil when valid; otherwise why Save and lock is disabled beyond the running total.
    var validationMessage: String? {
        guard split.isComplete else { return nil }
        do {
            try store.ledger.validateWithdrawal(amount: request.amount, split: split)
            return nil
        } catch let error as LedgerError {
            return error.message
        } catch {
            return userMessage(for: error)
        }
    }

    var canSave: Bool { split.isComplete && validationMessage == nil }

    func save() async throws {
        try await store.recordWithdrawal(
            amount: request.amount,
            split: split,
            source: request.source,
            fetchedBalance: request.fetchedBalance
        )
    }
}
