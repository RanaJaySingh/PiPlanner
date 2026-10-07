import Foundation

/// A fetched or PIN-checked balance compared with the snapshot, waiting for the customer's Continue.
struct SyncPreview: Identifiable, Hashable, Sendable {
    let id = UUID()
    let previous: Decimal
    let fetched: Decimal
    let source: HistoryEntry.Source
    /// True when amounts were typed since the last read, so everything else arrives as one amount (20c).
    let isCatchUp: Bool

    var delta: Decimal { fetched - previous }
    var isIncrease: Bool { fetched > previous }
}

enum BalanceReading: Hashable, Sendable {
    case unchanged
    case changed(SyncPreview)
}
