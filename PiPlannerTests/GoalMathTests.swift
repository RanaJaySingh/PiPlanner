import Foundation
import Testing
@testable import PiPlanner

@Suite("Goal maths")
struct GoalMathTests {
    private let october = Fixture.october

    @Test("Months count both ends: Oct 2026 to Sep 2030 is 48")
    func monthsInclusive() {
        #expect(october.monthsInclusive(through: YearMonth(year: 2030, month: 9)) == 48)
        #expect(october.monthsInclusive(through: october) == 1)
        #expect(october.monthsInclusive(through: october.adding(months: -1)) == 0)
    }

    @Test("Required monthly after the opening split")
    func requiredMonthly() {
        #expect(GoalMath.requiredMonthly(target: 1_000_000, saved: 60_000, monthsRemaining: 48) == 19_583)
        #expect(GoalMath.requiredMonthly(target: 200_000, saved: 40_000, monthsRemaining: 12) == 13_333)
        #expect(GoalMath.requiredMonthly(target: 1_000_000, saved: 0, monthsRemaining: 48) == 20_833)
        #expect(GoalMath.requiredMonthly(target: 1_000_000, saved: 100_000, monthsRemaining: 48) == 18_750)
    }

    @Test("Nothing is required once a goal is fully saved or has ended")
    func requiredMonthlyEdges() {
        #expect(GoalMath.requiredMonthly(target: 100, saved: 200, monthsRemaining: 5) == 0)
        #expect(GoalMath.requiredMonthly(target: 100, saved: 0, monthsRemaining: 0) == 0)
    }

    @Test("Months remaining counts from the later of today and the start")
    func monthsRemaining() {
        let end = YearMonth(year: 2030, month: 9)
        #expect(GoalMath.monthsRemaining(start: october, end: end, asOf: october) == 48)
        #expect(GoalMath.monthsRemaining(start: october, end: end, asOf: october.adding(months: 1)) == 47)
        #expect(GoalMath.monthsRemaining(start: october.adding(months: 3), end: end, asOf: october) == 45)
    }

    @Test("Next month occurrence")
    func nextMonth() {
        #expect(october.adding(months: 1).next(month: 3) == YearMonth(year: 2027, month: 3))
        #expect(october.next(month: 10) == october)
    }
}

@Suite("Splits and apportionment")
struct SplitTests {
    @Test("Largest remainder adds up exactly")
    func largestRemainder() {
        let parts = Apportion.largestRemainder(total: 100, weights: [1, 1, 1], unit: 1)
        #expect(parts == [34, 33, 33])
        #expect(parts.reduce(0, +) == 100)
    }

    @Test("Withdrawal proportional to 85k / 55k gives ₹4,857 and ₹3,143")
    func proportionalWithdrawal() {
        let car = UUID(), emergency = UUID()
        let split = Split.proportional(to: [(car, 85_000), (emergency, 55_000)])
        #expect(split.isComplete)
        let slices = split.allocate(-8_000)
        #expect(slices.map(\.amount) == [-4_857, -3_143])
    }

    @Test("Allocation is whole rupees and sums to the amount")
    func allocate() {
        let ids = [UUID(), UUID(), UUID()]
        let split = Fixture.split([(ids[0], 50), (ids[1], 30), (ids[2], 20)])
        let slices = split.allocate(50_000)
        #expect(slices.map(\.amount) == [25_000, 15_000, 10_000])
        let odd = Split.equal(ids).allocate(10_001)
        #expect(odd.reduce(0) { $0 + $1.amount } == 10_001)
    }

    @Test("Normalising 50 / 30 gives 62.5 / 37.5")
    func normalised() {
        let car = UUID(), emergency = UUID()
        let split = Fixture.split([(car, 50), (emergency, 30)]).normalised()
        #expect(split[car] == 62.5)
        #expect(split[emergency] == 37.5)
    }

    @Test("Equal split of one goal is 100%")
    func equalOne() {
        let id = UUID()
        #expect(Split.equal([id])[id] == 100)
    }
}
