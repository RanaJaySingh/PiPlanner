import Foundation

protocol AppClock: Sendable {
    var now: Date { get }
}

struct SystemClock: AppClock {
    var now: Date { Date() }
}

struct FixedClock: AppClock {
    let now: Date
}
