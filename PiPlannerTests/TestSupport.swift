import Foundation
@testable import PiPlanner

/// Shared fixtures for Rahul's demo.
enum Fixture {
    static let october = DemoScenario.start
    static let calendar = DemoScenario.calendar

    static func ledger(_ stage: DemoScenario.Stage) -> Ledger {
        DemoScenario.ledger(at: stage)
    }

    static func goalID(_ name: String, in ledger: Ledger) -> UUID {
        guard let goal = ledger.goals.first(where: { $0.name == name }) else {
            preconditionFailure("No goal named \(name)")
        }
        return goal.id
    }

    static func progress(_ name: String, in ledger: Ledger) -> GoalProgress? {
        ledger.progress(of: goalID(name, in: ledger), asOf: october, calendar: calendar)
    }

    static func split(_ pairs: [(UUID, Decimal)]) -> Split {
        Split(pairs.map { Split.Share(goalID: $0.0, percent: $0.1) })
    }

    /// Opening ₹1,00,000 at 60/40, then a ₹40,000 credit at 62.5/37.5: Car ₹85,000, Emergency ₹55,000.
    static func ledgerWithEightyFiveFiftyFive() throws -> Ledger {
        var ledger = Self.ledger(.afterOpening)
        let car = goalID("Car", in: ledger)
        let emergency = goalID("Emergency", in: ledger)
        let entry = try ledger.beginCredit(amount: 40_000, source: .fetched, fetchedBalance: 140_000, date: DemoScenario.date(day: 3))
        try ledger.changeSplit(ofEntry: entry, to: split([(car, 62.5), (emergency, 37.5)]), carryForward: false)
        try ledger.saveEntry(entry)
        return ledger
    }
}

/// A Grok client that returns a fixed reply, for orchestrator tests.
struct StubGrokClient: GrokClient {
    let reply: GrokReply

    func reply(to request: GrokRequest) async throws -> GrokReply { reply }
}

struct StubGrokProvider: GrokClientProviding {
    let client: (any GrokClient)?

    func makeClient() -> (any GrokClient)? { client }
}

struct FailingGrokClient: GrokClient {
    struct Failure: Error {}

    func reply(to request: GrokRequest) async throws -> GrokReply { throw Failure() }
}

/// Records the last request so tests can inspect what would leave the device.
actor RequestRecorder {
    private(set) var last: GrokRequest?

    func record(_ request: GrokRequest) { last = request }
}

struct RecordingGrokClient: GrokClient {
    let recorder: RequestRecorder

    func reply(to request: GrokRequest) async throws -> GrokReply {
        await recorder.record(request)
        return try await MockGrokClient().reply(to: request)
    }
}
