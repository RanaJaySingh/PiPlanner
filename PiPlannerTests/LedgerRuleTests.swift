import Foundation
import Testing
@testable import PiPlanner

/// The QA matrix rules: what the engine refuses, and the invariants that must always hold.
@Suite("Ledger · rules and invariants")
struct LedgerRuleTests {
    private let day = DemoScenario.date(day: 5)

    // MARK: - Setup

    @Test("Setup needs a dedicated account and at least one valid goal")
    func setupGuards() {
        var ledger = DemoProfile.makeLedger()
        ledger.markDedicated(nil)
        #expect(throws: LedgerError.noDedicatedAccount) { try ledger.setConsent(isOn: true) }

        ledger.markDedicated(ledger.accounts[0].id)
        #expect(throws: LedgerError.noGoals) {
            try ledger.completeSetup(goals: [], openingBalance: 100_000, source: .typed, date: day)
        }
        var invalid = DemoProfile.goalDrafts(start: Fixture.october)[0]
        invalid.end = invalid.start
        #expect(throws: LedgerError.invalidGoal(.endNotAfterStart)) {
            try ledger.completeSetup(goals: [invalid], openingBalance: 100_000, source: .typed, date: day)
        }
    }

    @Test("Opening percentages must sum to 100")
    func openingMustSumTo100() {
        var ledger = DemoProfile.makeLedger()
        var drafts = DemoProfile.goalDrafts(start: Fixture.october)
        drafts[1].standingPercent = 30
        #expect(throws: LedgerError.splitIncomplete) {
            try ledger.completeSetup(goals: drafts, openingBalance: 100_000, source: .typed, date: day)
        }
    }

    @Test("Marking one account dedicated turns the other off")
    func oneDedicatedAccount() {
        var ledger = DemoProfile.makeLedger()
        ledger.markDedicated(ledger.accounts[1].id)
        #expect(ledger.accounts.filter { $0.role == .dedicatedSavings }.map(\.id) == [ledger.accounts[1].id])
    }

    // MARK: - Balance changes

    @Test("Balance change: unchanged, higher, lower")
    func balanceChange() throws {
        let ledger = Fixture.ledger(.afterOpening)
        #expect(try ledger.balanceChange(forFetched: 100_000) == .unchanged)
        #expect(try ledger.balanceChange(forFetched: 150_000) == .increased(by: 50_000))
        #expect(try ledger.balanceChange(forFetched: 92_000) == .decreased(by: 8_000))
    }

    @Test("Only one entry can be open; withdrawals wait too")
    func oneOpenEntry() {
        var ledger = Fixture.ledger(.openCredit)
        #expect(throws: LedgerError.entryAlreadyOpen) {
            try ledger.beginCredit(amount: 1_000, source: .typed, fetchedBalance: nil, date: day)
        }
        #expect(throws: LedgerError.entryAlreadyOpen) {
            try ledger.recordWithdrawal(amount: 1_000, split: ledger.withdrawalProposal(), source: .typed, fetchedBalance: nil, date: day)
        }
    }

    @Test("The split of an entry changes once, and only while open")
    func splitChangesOnce() throws {
        var ledger = Fixture.ledger(.openCredit)
        let entry = try #require(ledger.openEntry)
        let ids = ledger.activeGoalIDs
        try ledger.changeSplit(ofEntry: entry.id, to: Fixture.split([(ids[0], 70), (ids[1], 30)]), carryForward: false)
        #expect(throws: LedgerError.splitAlreadyChanged) {
            try ledger.changeSplit(ofEntry: entry.id, to: Fixture.split([(ids[0], 50), (ids[1], 50)]), carryForward: false)
        }
        try ledger.saveEntry(entry.id)
        #expect(throws: LedgerError.entryNotOpen) { try ledger.saveEntry(entry.id) }
    }

    @Test("A split that does not sum to 100 is refused and changes nothing")
    func incompleteSplitRefused() throws {
        var ledger = Fixture.ledger(.openCredit)
        let before = ledger
        let entry = try #require(ledger.openEntry)
        let ids = ledger.activeGoalIDs
        #expect(throws: LedgerError.splitIncomplete) {
            try ledger.changeSplit(ofEntry: entry.id, to: Fixture.split([(ids[0], 50), (ids[1], 30)]), carryForward: false)
        }
        #expect(ledger == before)
    }

    @Test("Amounts must be positive")
    func positiveAmounts() {
        var ledger = Fixture.ledger(.afterOpening)
        #expect(throws: LedgerError.nonPositiveAmount) {
            try ledger.beginCredit(amount: 0, source: .typed, fetchedBalance: nil, date: day)
        }
    }

    // MARK: - Goals

    @Test("A goal created outside an entry starts at ₹0 and takes its share proportionally")
    func standaloneGoal() throws {
        var ledger = Fixture.ledger(.afterOpening)
        var home = GoalDraft(name: "Home", target: 500_000, start: Fixture.october, end: Fixture.october.adding(months: 59))
        home.standingPercent = 20
        let id = try ledger.createGoal(home, placement: .standalone)
        #expect(ledger.saved(id) == 0)
        #expect(ledger.activeGoals.map(\.standingPercent) == [48, 32, 20])
        #expect(ledger.standingSplit.isComplete)
    }

    @Test("Goal edits are held until the next entry of any kind")
    func pendingEdits() throws {
        var ledger = Fixture.ledger(.afterCustomCredit)
        let car = Fixture.goalID("Car", in: ledger)
        var draft = GoalDraft(goal: try #require(ledger.goal(car)))
        draft.end = YearMonth(year: 2031, month: 9)
        draft.standingPercent = 40
        try ledger.stageEdit(draft.edit, for: car)

        #expect(ledger.goal(car)?.pendingEdit != nil)
        #expect(ledger.goal(car)?.end == YearMonth(year: 2030, month: 9), "Nothing changes before the next entry")
        #expect(ledger.goal(car)?.effective.end == YearMonth(year: 2031, month: 9))

        let emergency = Fixture.goalID("Emergency", in: ledger)
        try ledger.transfer(from: emergency, to: car, amount: 5_000, date: day)
        #expect(ledger.goal(car)?.pendingEdit == nil)
        #expect(ledger.goal(car)?.end == YearMonth(year: 2031, month: 9))
        #expect(ledger.activeGoals.map(\.standingPercent) == [40, 36, 24], "The others make room proportionally")
    }

    @Test("Transfers cannot exceed the saved amount or use the same goal")
    func transferGuards() {
        var ledger = Fixture.ledger(.afterCustomCredit)
        let car = Fixture.goalID("Car", in: ledger)
        let emergency = Fixture.goalID("Emergency", in: ledger)
        #expect(throws: LedgerError.insufficientSavings) {
            try ledger.transfer(from: emergency, to: car, amount: 60_000, date: day)
        }
        #expect(throws: LedgerError.sameGoal) {
            try ledger.transfer(from: car, to: car, amount: 1_000, date: day)
        }
    }

    @Test("The last goal cannot be deleted without a receiver")
    func lastGoalNeedsReceiver() throws {
        var ledger = DemoProfile.makeLedger()
        let car = DemoProfile.goalDrafts(start: Fixture.october)[0]
        try ledger.completeSetup(goals: [car], openingBalance: 100_000, source: .typed, date: day)
        #expect(ledger.deletionProposal(for: car.id).isEmpty)
        #expect(throws: LedgerError.lastGoalNeedsReceiver) {
            try ledger.deleteGoal(car.id, redistribution: Split(), date: day)
        }

        let vacation = try ledger.createGoal(DemoProfile.vacationDraft(start: Fixture.october), placement: .onDeletion(of: car.id))
        try ledger.deleteGoal(car.id, redistribution: ledger.deletionProposal(for: car.id), date: day)
        #expect(ledger.saved(vacation) == 100_000)
        #expect(ledger.standingSplit[vacation] == 100)
    }

    @Test("Deleting a goal during an open entry removes it from that entry's split")
    func deleteDuringOpenEntry() throws {
        var ledger = Fixture.ledger(.openCredit)
        let emergency = Fixture.goalID("Emergency", in: ledger)
        let car = Fixture.goalID("Car", in: ledger)
        try ledger.deleteGoal(emergency, redistribution: Fixture.split([(car, 100)]), date: day)
        let entry = try #require(ledger.openEntry)
        #expect(entry.split.goalIDs == [car])
        #expect(entry.slices.map(\.amount) == [50_000])
    }

    // MARK: - Withdrawals

    @Test("Withdrawals cannot take a goal below ₹0 or exceed everything saved")
    func withdrawalGuards() throws {
        let ledger = Fixture.ledger(.afterCustomCredit)
        let vacation = Fixture.goalID("Vacation", in: ledger)
        #expect(throws: LedgerError.reductionExceedsSaving) {
            try ledger.validateWithdrawal(amount: 20_000, split: Fixture.split([(vacation, 100)]))
        }
        #expect(throws: LedgerError.withdrawalExceedsSavings) {
            try ledger.validateWithdrawal(amount: 200_000, split: ledger.withdrawalProposal())
        }
        #expect(throws: LedgerError.splitIncomplete) {
            let ids = ledger.activeGoalIDs
            try ledger.validateWithdrawal(amount: 8_000, split: Fixture.split([(ids[0], 80), (ids[1], 10)]))
        }
    }

    // MARK: - Invariants

    @Test("Assigned money equals the snapshot whenever no entry is open", arguments: [
        DemoScenario.Stage.afterOpening, .afterCustomCredit, .afterTransfer,
    ])
    func assignedEqualsSnapshot(stage: DemoScenario.Stage) {
        let ledger = Fixture.ledger(stage)
        #expect(ledger.openEntry == nil)
        #expect(ledger.assignedTotal == ledger.snapshot)
    }

    @Test("Saved amounts are derived from saved slices, so History cannot drift")
    func savedIsDerived() {
        let ledger = Fixture.ledger(.afterTransfer)
        for goal in ledger.activeGoals {
            let fromHistory = ledger.slices(for: goal.id).reduce(0) { $0 + $1.amount }
            #expect(fromHistory == ledger.saved(goal.id))
        }
    }

    @Test("Every saved entry's slices add up to its effect on the balance")
    func slicesBalance() {
        let ledger = Fixture.ledger(.afterTransfer)
        for entry in ledger.history where entry.state == .saved {
            let total = entry.slices.reduce(0) { $0 + $1.amount }
            #expect(total == entry.newBalance - entry.previousBalance || entry.kind == .opening)
        }
    }

    @Test("Automatic, PIN-check and typed credits write the same entry for the same amount")
    func routesAgree() throws {
        let base = Fixture.ledger(.afterOpening)
        let routes: [(HistoryEntry.Source, Decimal?)] = [(.fetched, 150_000), (.pinCheck, 150_000), (.typed, nil)]
        let results = try routes.map { source, fetched -> (slices: [Decimal], snapshot: Decimal?) in
            var ledger = base
            let id = try ledger.beginCredit(amount: 50_000, source: source, fetchedBalance: fetched, date: day)
            try ledger.saveEntry(id)
            let entry = try #require(ledger.history.first { $0.id == id })
            return (entry.slices.map(\.amount), ledger.snapshot)
        }
        for result in results {
            #expect(result.slices == [30_000, 20_000])
            #expect(result.snapshot == 150_000)
        }
    }

    @Test("The ledger round-trips through Codable")
    func codable() throws {
        let ledger = Fixture.ledger(.afterTransfer)
        let data = try JSONEncoder().encode(ledger)
        #expect(try JSONDecoder().decode(Ledger.self, from: data) == ledger)
    }
}
