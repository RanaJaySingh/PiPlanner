import Foundation

/// One row in History: an opening split, a new amount, a transfer, a deletion or a withdrawal.
struct HistoryEntry: Identifiable, Hashable, Codable, Sendable {
    enum Kind: String, Hashable, Codable, Sendable {
        case opening
        case credit
        case transfer
        case goalDeleted
        case withdrawal
    }

    /// How the balance behind the entry was obtained: automatic fetch, PIN balance check, or typed.
    enum Source: String, Hashable, Codable, Sendable {
        case fetched
        case pinCheck
        case typed
    }

    /// Open means the one-time change is still available.
    enum State: String, Hashable, Codable, Sendable {
        case open
        case saved
    }

    struct Transfer: Hashable, Codable, Sendable {
        let fromGoalID: UUID
        let toGoalID: UUID
    }

    let id: UUID
    let kind: Kind
    /// Nil for transfers and deletions, which do not read a balance.
    let source: Source?
    let date: Date
    let previousBalance: Decimal
    /// Nil when the amount was typed.
    let fetchedBalance: Decimal?
    /// Size of the event, always positive: the credit, the withdrawal, the transfer, or the released saving.
    let amount: Decimal
    var state: State
    var split: Split
    /// Replaced once while open, frozen on save.
    var slices: [Slice]
    var customSplit = false
    /// "Use this split from the next credit too".
    var carriesSplitForward = false
    /// The goal removed by a `.goalDeleted` entry.
    var deletedGoalID: UUID?
    var transfer: Transfer?

    init(
        id: UUID = UUID(),
        kind: Kind,
        source: Source?,
        date: Date,
        previousBalance: Decimal,
        fetchedBalance: Decimal?,
        amount: Decimal,
        state: State,
        split: Split,
        slices: [Slice],
        deletedGoalID: UUID? = nil,
        transfer: Transfer? = nil
    ) {
        self.id = id
        self.kind = kind
        self.source = source
        self.date = date
        self.previousBalance = previousBalance
        self.fetchedBalance = fetchedBalance
        self.amount = amount
        self.state = state
        self.split = split
        self.slices = slices
        self.deletedGoalID = deletedGoalID
        self.transfer = transfer
    }

    var isOpen: Bool { state == .open }

    var newBalance: Decimal {
        switch kind {
        case .opening: amount
        case .credit: previousBalance + amount
        case .withdrawal: previousBalance - amount
        case .transfer, .goalDeleted: previousBalance
        }
    }

    func slice(for goalID: UUID) -> Decimal {
        slices.filter { $0.goalID == goalID }.reduce(0) { $0 + $1.amount }
    }
}
