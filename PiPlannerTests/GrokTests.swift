import Foundation
import Testing
@testable import PiPlanner

@Suite("UtteranceParser")
struct UtteranceParserTests {
    let parser = UtteranceParser(today: Fixture.october)

    @Test("Rupee amounts in lakh, k and grouped digits; bare years are ignored")
    func amounts() {
        #expect(parser.amounts(in: "A ₹10 lakh car by Sep 2030") == [1_000_000])
        #expect(parser.amounts(in: "Move 5k from Emergency to Car") == [5_000])
        #expect(parser.amounts(in: "Add a ₹50,000 vacation") == [50_000])
        #expect(parser.amounts(in: "₹1.5 cr home") == [15_000_000])
        #expect(parser.amounts(in: "by 2030, 20% each").isEmpty)
    }

    @Test("End months: explicit year, next occurrence, and relative")
    func endMonths() {
        #expect(parser.endMonth(in: "by Sep 2030") == YearMonth(year: 2030, month: 9))
        #expect(parser.endMonth(in: "by March") == YearMonth(year: 2027, month: 3))
        #expect(parser.endMonth(in: "an emergency fund in a year") == YearMonth(year: 2027, month: 9))
        #expect(parser.endMonth(in: "in 6 months") == YearMonth(year: 2027, month: 3))
        #expect(parser.endMonth(in: "soon") == nil)
    }

    @Test("Goal names, clauses, questions and transfers")
    func structure() {
        #expect(parser.goalName(in: "a Goa holiday") == "Goa trip")
        #expect(parser.goalName(in: "a ₹2 lakh emergency fund") == "Emergency")
        #expect(parser.goalName(in: "something nice") == nil)
        #expect(parser.goalNamed("emerg", among: ["Car", "Emergency"]) == "Emergency")
        #expect(parser.clauses(of: GoalChatViewModel.suggestion).count == 2)
        #expect(parser.percent(in: "give it 25%") == 25)
        #expect(parser.isQuestion("How are my goals doing?"))
        #expect(parser.isQuestion("what happens if I change the split"))
        #expect(!parser.isQuestion("Add a trip"))
        #expect(parser.transferEndpoints(in: "Move 5k from Emergency to Car")?.from == "Emergency")
        #expect(parser.transferEndpoints(in: "Move 5k from Emergency to Car")?.to == "Car")
        #expect(parser.asksToMoveMoneyOut("Send ₹5,000 to Ravi"))
        #expect(!parser.asksToMoveMoneyOut("Move 5k from Emergency to Car"))
    }
}

@Suite("Grok orchestrator")
struct GrokOrchestratorTests {
    /// Goal ids are fresh per ledger, so pass `ledger` when the test compares ids.
    private func respond(
        _ text: String,
        surface: GrokSurface = .ask,
        stage: DemoScenario.Stage,
        ledger: Ledger? = nil,
        followUps: Int = 0,
        client: (any GrokClient)? = MockGrokClient(),
        readyToSplit: Decimal? = nil
    ) async -> GrokOutcome {
        let orchestrator = GrokOrchestrator(provider: StubGrokProvider(client: client))
        return await orchestrator.respond(
            to: text,
            surface: surface,
            ledger: ledger ?? Fixture.ledger(stage),
            readyToSplit: readyToSplit,
            followUpCount: followUps,
            asOf: Fixture.october,
            calendar: Fixture.calendar
        )
    }

    // MARK: - Demo sentences

    @Test("Setup sentence drafts Car and Emergency at 60/40")
    func setupSentence() async throws {
        let outcome = await respond(GoalChatViewModel.suggestion, surface: .goalSetup, stage: .welcome, readyToSplit: 100_000)
        guard case let .goalDrafts(drafts) = outcome else {
            Issue.record("Expected goal drafts, got \(outcome)")
            return
        }
        try #require(drafts.count == 2)
        #expect(drafts[0].trimmedName == "Car")
        #expect(drafts[0].target == 1_000_000)
        #expect(drafts[0].end == YearMonth(year: 2030, month: 9))
        #expect(drafts[1].trimmedName == "Emergency")
        #expect(drafts[1].target == 200_000)
        #expect(drafts[1].end == YearMonth(year: 2027, month: 9))
        #expect(drafts.map(\.standingPercent) == [60, 40])
    }

    @Test("A goal on the open entry becomes entry_goal with a 50/30/20 split")
    func entryGoal() async throws {
        let ledger = Fixture.ledger(.openCredit)
        let outcome = await respond("Add a ₹50,000 vacation by March", stage: .openCredit, ledger: ledger)
        guard case let .entryGoal(proposal) = outcome else {
            Issue.record("Expected entry goal, got \(outcome)")
            return
        }
        #expect(proposal.draft.trimmedName == "Vacation")
        #expect(proposal.draft.target == 50_000)
        #expect(proposal.draft.end == YearMonth(year: 2027, month: 3))
        #expect(proposal.split[Fixture.goalID("Car", in: ledger)] == 50)
        #expect(proposal.split[Fixture.goalID("Emergency", in: ledger)] == 30)
        #expect(proposal.split[proposal.draft.id] == 20)
        #expect(proposal.split.isComplete)
    }

    @Test("Demo sentence: 20% of this into a ₹50,000 Goa trip by March")
    func goaTripAtTwentyPercent() async throws {
        let ledger = Fixture.ledger(.openCredit)
        let outcome = await respond("Put 20% of this into a ₹50,000 Goa trip by March", stage: .openCredit, ledger: ledger)
        guard case let .entryGoal(proposal) = outcome else {
            Issue.record("Expected entry goal, got \(outcome)")
            return
        }
        #expect(proposal.draft.trimmedName == "Goa trip")
        #expect(proposal.draft.target == 50_000)
        #expect(proposal.split[Fixture.goalID("Car", in: ledger)] == 50)
        #expect(proposal.split[Fixture.goalID("Emergency", in: ledger)] == 30)
        #expect(proposal.split[proposal.draft.id] == 20)
    }

    @Test("Move 5k from Emergency to Car proposes a transfer")
    func transfer() async {
        let ledger = Fixture.ledger(.afterCustomCredit)
        let outcome = await respond("Move 5k from Emergency to Car", stage: .afterCustomCredit, ledger: ledger)
        #expect(outcome == .transfer(TransferProposal(
            fromGoalID: Fixture.goalID("Emergency", in: ledger),
            toGoalID: Fixture.goalID("Car", in: ledger),
            amount: 5_000
        )))
    }

    @Test("A transfer above the saved amount asks again instead")
    func transferTooLarge() async {
        let outcome = await respond("Move ₹1 lakh from Emergency to Car", stage: .afterCustomCredit)
        #expect(outcome == .followUp("Emergency has ₹55,000 saved. How much should move?"))
    }

    @Test("A goal without amount or date gets one follow-up in Ask, then the form")
    func askFollowUp() async {
        let first = await respond("Add a trip", stage: .afterCustomCredit)
        #expect(first == .followUp("How much is the trip, and by when?"))
        let second = await respond("Soon", stage: .afterCustomCredit, followUps: 1)
        #expect(second == .openForm)
    }

    @Test("Setup allows two follow-ups before handing over to the form")
    func setupFollowUps() async {
        let first = await respond("I want to save for a car", surface: .goalSetup, stage: .welcome)
        guard case .followUp = first else {
            Issue.record("Expected a follow-up, got \(first)")
            return
        }
        let second = await respond("Soon", surface: .goalSetup, stage: .welcome, followUps: 1)
        #expect(second == .followUp("Roughly how much, and which month and year?"))
        let third = await respond("Soon", surface: .goalSetup, stage: .welcome, followUps: 2)
        #expect(third == .openForm)
    }

    @Test("Questions are answered from the engine's figures")
    func goalsQuestion() async {
        let outcome = await respond("How are my goals doing?", stage: .afterCustomCredit)
        guard case let .answer(text) = outcome else {
            Issue.record("Expected an answer, got \(outcome)")
            return
        }
        #expect(text.contains("Car has ₹85,000 of ₹10,00,000 and needs ₹19,063 a month"))
    }

    @Test("Payments are refused")
    func unsupported() async {
        let outcome = await respond("Send ₹5,000 to Ravi", stage: .afterCustomCredit)
        guard case .unsupported = outcome else {
            Issue.record("Expected unsupported, got \(outcome)")
            return
        }
    }

    // MARK: - Validation

    @Test("Answers quoting rupee figures the engine never produced fall back to the template")
    func rupeeAudit() async {
        let ledger = Fixture.ledger(.afterCustomCredit)
        let context = GrokOrchestrator.context(ledger: ledger, asOf: Fixture.october, calendar: Fixture.calendar)
        let invented = StubGrokClient(reply: GrokReply(kind: .answer, message: "Car needs ₹99,999 a month."))
        let outcome = await respond("How is Car doing?", stage: .afterCustomCredit, ledger: ledger, client: invented)
        #expect(outcome == .answer(PlanExplainer.summaryAnswer(context: context)))

        let plain = StubGrokClient(reply: GrokReply(kind: .answer, message: "Car is on track."))
        #expect(await respond("How is Car doing?", stage: .afterCustomCredit, ledger: ledger, client: plain) == .answer("Car is on track."))
    }

    @Test("Goals with an end date in the past are not proposed")
    func invalidGoal() async {
        let stale = StubGrokClient(reply: GrokReply(kind: .goals, goals: [
            .init(name: "Car", target: 1_000_000, end: "2020-01"),
        ]))
        let outcome = await respond("A car", surface: .goalSetup, stage: .welcome, client: stale)
        guard case .followUp = outcome else {
            Issue.record("Expected a follow-up, got \(outcome)")
            return
        }
    }

    @Test("A transfer naming an unknown goal is not proposed")
    func unknownTransferGoal() async {
        let reply = StubGrokClient(reply: GrokReply(kind: .transfer, transfer: .init(from: "Boat", to: "Car", amount: 5_000)))
        let outcome = await respond("Move 5k from Boat to Car", stage: .afterCustomCredit, client: reply)
        guard case .followUp = outcome else {
            Issue.record("Expected a follow-up, got \(outcome)")
            return
        }
    }

    @Test("No client, or a failing one, means unavailable")
    func unavailable() async {
        #expect(await respond("Add a trip", stage: .afterOpening, client: nil) == .unavailable)
        #expect(await respond("Add a trip", stage: .afterOpening, client: FailingGrokClient()) == .unavailable)
    }

    // MARK: - Trust boundary

    @Test("The request leaving the device carries no account data")
    func trustBoundary() async throws {
        let ledger = Fixture.ledger(.afterCustomCredit)
        let recorder = RequestRecorder()
        _ = await respond("How are my goals doing?", stage: .afterCustomCredit, ledger: ledger, client: RecordingGrokClient(recorder: recorder))
        let request = try #require(await recorder.last)
        let json = try #require(String(data: JSONEncoder().encode(request), encoding: .utf8))

        let forbidden = ["4821", "7730", "HDFC", "SBI", "Savings", "Spending"] + ledger.accounts.map(\.id.uuidString)
        for value in forbidden {
            #expect(!json.localizedCaseInsensitiveContains(value), "Request leaked \(value)")
        }
        #expect(json.contains("Car"))
    }
}
