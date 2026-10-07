import Foundation

/// A signed amount of one entry assigned to one goal. A transfer is one negative and one positive slice.
struct Slice: Hashable, Codable, Sendable {
    let goalID: UUID
    let amount: Decimal
}

/// Percentages across goals. Order is preserved for display.
struct Split: Hashable, Codable, Sendable {
    struct Share: Identifiable, Hashable, Codable, Sendable {
        let goalID: UUID
        var percent: Decimal
        var id: UUID { goalID }
    }

    private(set) var shares: [Share]

    init(_ shares: [Share] = []) {
        self.shares = shares
    }

    var goalIDs: [UUID] { shares.map(\.goalID) }
    var total: Decimal { shares.reduce(0) { $0 + $1.percent } }
    var isComplete: Bool { !shares.isEmpty && total == 100 }
    var isEmpty: Bool { shares.isEmpty }

    subscript(goalID: UUID) -> Decimal {
        get { shares.first { $0.goalID == goalID }?.percent ?? 0 }
        set {
            if let index = shares.firstIndex(where: { $0.goalID == goalID }) {
                shares[index].percent = newValue
            } else {
                shares.append(Share(goalID: goalID, percent: newValue))
            }
        }
    }

    func contains(_ goalID: UUID) -> Bool {
        shares.contains { $0.goalID == goalID }
    }

    mutating func remove(_ goalID: UUID) {
        shares.removeAll { $0.goalID == goalID }
    }

    /// Whole-rupee amounts per goal that add up exactly to `amount`. Negative amounts give negative slices.
    func allocate(_ amount: Decimal) -> [Slice] {
        let magnitude = abs(amount).rounded()
        let parts = Apportion.largestRemainder(total: magnitude, weights: shares.map(\.percent), unit: 1)
        let sign: Decimal = amount < 0 ? -1 : 1
        return zip(shares, parts).map { Slice(goalID: $0.goalID, amount: $1 * sign) }
    }

    func amount(for goalID: UUID, of total: Decimal) -> Decimal {
        allocate(total).first { $0.goalID == goalID }?.amount ?? 0
    }

    /// Same goals, scaled so they add to 100. All-zero shares become equal.
    func normalised() -> Split {
        guard !shares.isEmpty else { return self }
        guard total > 0 else { return .equal(goalIDs) }
        return .proportional(to: shares.map { ($0.goalID, $0.percent) })
    }

    static func equal(_ goalIDs: [UUID]) -> Split {
        proportional(to: goalIDs.map { ($0, 1) })
    }

    /// Percentages proportional to `weights`, in steps of `step`, adding to 100.
    static func proportional(to weights: [(UUID, Decimal)], step: Decimal = 1 / 100) -> Split {
        let parts = Apportion.largestRemainder(total: 100, weights: weights.map(\.1), unit: step)
        return Split(zip(weights, parts).map { Share(goalID: $0.0, percent: $1) })
    }
}
