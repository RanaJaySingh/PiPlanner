import Foundation
import Testing
@testable import PiPlanner

/// Rahul's demo numbers, end to end through the engine.
@Suite("Ledger · Rahul's demo")
struct LedgerDemoTests {
    @Test("Opening split: Car ₹60,000, Emergency ₹40,000")
    func openingSplit() throws {
        let ledger = Fixture.ledger(.afterOpening)
        let car = try #require(Fixture.progress("Car", in: ledger))
        let emergency = try #require(Fixture.progress("Emergency", in: ledger))

        #expect(car.saved == 60_000)
        #expect(car.target == 1_000_000)
        #expect(car.requiredMonthly == 19_583)
        #expect(car.status == .onTrack)
        #expect(emergency.saved == 40_000)
        #expect(emergency.target == 200_000)
        #expect(emergency.requiredMonthly == 13_333)
        #expect(ledger.snapshot == 100_000)
        #expect(ledger.history.count == 1)
        #expect(ledger.history[0].kind == .opening)
    }

    @Test("A single goal takes 100% of the opening balance")
    func singleGoalOpening() throws {
        var ledger = DemoProfile.makeLedger()
        try ledger.setConsent(isOn: false)
        var car = DemoProfile.goalDrafts(start: Fixture.october)[0]
        car.standingPercent = 0
        try ledger.completeSetup(goals: [car], openingBalance: 100_000, source: .typed, date: DemoScenario.date(day: 1))
        let progress = try #require(Fixture.progress("Car", in: ledger))
        #expect(progress.saved == 100_000)
        #expect(progress.requiredMonthly == 18_750)
        #expect(ledger.activeGoals[0].standingPercent == 100)
        #expect(ledger.history[0].fetchedBalance == nil)
    }

    @Test("Sync finds ₹50,000 and opens an entry with the 60 / 40 suggestion")
    func openCredit() throws {
        let ledger = Fixture.ledger(.openCredit)
        let entry = try #require(ledger.openEntry)
        #expect(entry.amount == 50_000)
        #expect(entry.previousBalance == 100_000)
        #expect(entry.newBalance == 150_000)
        #expect(entry.slices.map(\.amount) == [30_000, 20_000])
        #expect(ledger.saved(Fixture.goalID("Car", in: ledger)) == 60_000, "Open entries do not count yet")
        #expect(ledger.snapshot == 100_000)
    }

    @Test("Custom 50 / 30 / 20 credit keeps every goal on track")
    func customCredit() throws {
        let ledger = Fixture.ledger(.afterCustomCredit)
        let car = try #require(Fixture.progress("Car", in: ledger))
        let emergency = try #require(Fixture.progress("Emergency", in: ledger))
        let vacation = try #require(Fixture.progress("Vacation", in: ledger))

        #expect(car.saved == 85_000)
        #expect(car.requiredMonthly == 19_063)
        #expect(car.status == .onTrack)
        #expect(emergency.saved == 55_000)
        #expect(emergency.requiredMonthly == 12_083)
        #expect(emergency.status == .onTrack)
        #expect(vacation.saved == 10_000)
        #expect(vacation.target == 50_000)
        #expect(vacation.requiredMonthly == 6_667)
        #expect(vacation.status == .onTrack)
        #expect(ledger.snapshot == 150_000)
    }

    @Test("The carried-forward split becomes the standing split")
    func carryForward() {
        let ledger = Fixture.ledger(.afterCustomCredit)
        #expect(ledger.activeGoals.map(\.standingPercent) == [50, 30, 20])
    }

    @Test("Without carry forward the standing split stays 60 / 40 and the new goal gets 0%")
    func noCarryForward() throws {
        var ledger = Fixture.ledger(.openCredit)
        let entry = try #require(ledger.openEntry)
        let vacation = try ledger.createGoal(DemoProfile.vacationDraft(start: Fixture.october), placement: .onOpenEntry)
        let ids = ledger.activeGoalIDs
        try ledger.changeSplit(ofEntry: entry.id, to: Fixture.split([(ids[0], 50), (ids[1], 30), (vacation, 20)]), carryForward: false)
        try ledger.saveEntry(entry.id)
        #expect(ledger.activeGoals.map(\.standingPercent) == [60, 40, 0])
    }

    @Test("Shortfall preview: 50 / 30 / 20 covers every goal, 30 / 50 / 20 leaves Car ₹4,583 short")
    func shortfallPreview() throws {
        var ledger = Fixture.ledger(.openCredit)
        let entry = try #require(ledger.openEntry)
        let vacation = try ledger.createGoal(DemoProfile.vacationDraft(start: Fixture.october), placement: .onOpenEntry)
        let car = Fixture.goalID("Car", in: ledger)
        let emergency = Fixture.goalID("Emergency", in: ledger)
        let demoSplit = Fixture.split([(car, 50), (emergency, 30), (vacation, 20)])
        #expect(ledger.shortfalls(ifSaving: entry, with: demoSplit, asOf: Fixture.october, calendar: Fixture.calendar).isEmpty)
        let carLight = Fixture.split([(car, 30), (emergency, 50), (vacation, 20)])
        #expect(ledger.shortfalls(ifSaving: entry, with: carLight, asOf: Fixture.october, calendar: Fixture.calendar) == [car: 4_583])
    }

    @Test("Transfer ₹5,000: Car ₹90,000 needs ₹18,958, Emergency ₹50,000 needs ₹12,500")
    func transfer() throws {
        let ledger = Fixture.ledger(.afterTransfer)
        let car = try #require(Fixture.progress("Car", in: ledger))
        let emergency = try #require(Fixture.progress("Emergency", in: ledger))
        #expect(car.saved == 90_000)
        #expect(car.requiredMonthly == 18_958)
        #expect(emergency.saved == 50_000)
        #expect(emergency.requiredMonthly == 12_500)
        #expect(ledger.activeGoals.map(\.standingPercent) == [50, 30, 20], "Transfers leave the standing split alone")
        #expect(ledger.snapshot == 150_000)
    }

    @Test("Delete Vacation: equal 5,000 / 5,000, edited to 6,000 / 4,000, standing 62.5 / 37.5")
    func deleteVacation() throws {
        var ledger = Fixture.ledger(.afterTransfer)
        let vacation = Fixture.goalID("Vacation", in: ledger)
        let car = Fixture.goalID("Car", in: ledger)
        let emergency = Fixture.goalID("Emergency", in: ledger)

        let proposal = ledger.deletionProposal(for: vacation)
        #expect(proposal.allocate(ledger.saved(vacation)).map(\.amount) == [5_000, 5_000])

        try ledger.deleteGoal(vacation, redistribution: Fixture.split([(car, 60), (emergency, 40)]), date: DemoScenario.date(day: 5, hour: 21))
        #expect(ledger.saved(car) == 96_000)
        #expect(ledger.saved(emergency) == 54_000)
        #expect(ledger.saved(vacation) == 0)
        #expect(ledger.activeGoalIDs == [car, emergency])
        #expect(ledger.standingSplit[car] == 62.5)
        #expect(ledger.standingSplit[emergency] == 37.5)
        #expect(ledger.history.last?.kind == .goalDeleted)
        #expect(ledger.goal(vacation)?.isDeleted == true, "Deleted goals stay so old entries keep their names")
    }

    @Test("Withdrawal of ₹8,000 against ₹85,000 / ₹55,000 takes ₹4,857 and ₹3,143")
    func withdrawal() throws {
        var ledger = try Fixture.ledgerWithEightyFiveFiftyFive()
        let car = Fixture.goalID("Car", in: ledger)
        let emergency = Fixture.goalID("Emergency", in: ledger)
        let proposal = ledger.withdrawalProposal()

        try ledger.recordWithdrawal(amount: 8_000, split: proposal, source: .fetched, fetchedBalance: 132_000, date: DemoScenario.date(day: 5))
        #expect(ledger.saved(car) == 80_143)
        #expect(ledger.saved(emergency) == 51_857)
        #expect(ledger.history.last?.slices.map(\.amount) == [-4_857, -3_143])
        #expect(ledger.snapshot == 132_000)
    }

    @Test("The opening entry keeps its original amounts through every later change")
    func openingIsImmutable() throws {
        var ledger = Fixture.ledger(.afterTransfer)
        let opening = ledger.history[0]
        let vacation = Fixture.goalID("Vacation", in: ledger)
        try ledger.deleteGoal(vacation, redistribution: ledger.deletionProposal(for: vacation), date: DemoScenario.date(day: 6))
        #expect(ledger.history[0] == opening)
        #expect(ledger.history[0].slices.map(\.amount) == [60_000, 40_000])
    }
}
