import Foundation

extension Decimal {
    /// Rounds to `scale` fraction digits. `.plain` rounds halves away from zero.
    func rounded(scale: Int = 0, mode: NSDecimalNumber.RoundingMode = .plain) -> Decimal {
        var source = self
        var result = Decimal()
        NSDecimalRound(&result, &source, scale, mode)
        return result
    }

    var doubleValue: Double {
        NSDecimalNumber(decimal: self).doubleValue
    }
}

enum Apportion {
    /// Splits `total` across `weights` in multiples of `unit` so the parts add up exactly
    /// (largest-remainder method). Ties go to the earlier weight; non-positive weights get nothing.
    static func largestRemainder(total: Decimal, weights: [Decimal], unit: Decimal) -> [Decimal] {
        let positive = weights.map { max($0, 0) }
        let weightSum = positive.reduce(0, +)
        guard weightSum > 0, total > 0, unit > 0 else {
            return weights.map { _ in 0 }
        }

        let units = (total / unit).rounded(mode: .down)
        let exact = positive.map { units * $0 / weightSum }
        var parts = exact.map { $0.rounded(mode: .down) }
        var leftover = units - parts.reduce(0, +)

        let fractions = zip(exact, parts).map { $0 - $1 }
        let order = fractions.indices
            .filter { positive[$0] > 0 }
            .sorted { fractions[$0] == fractions[$1] ? $0 < $1 : fractions[$0] > fractions[$1] }

        var cursor = 0
        while leftover > 0, !order.isEmpty {
            parts[order[cursor % order.count]] += 1
            leftover -= 1
            cursor += 1
        }
        return parts.map { $0 * unit }
    }
}
