import Foundation
import Testing
@testable import PiPlanner

@Suite("Formatting")
struct FormattingTests {
    @Test("Rupees use Indian grouping and a true minus sign", arguments: [
        (Decimal(150_000), "₹1,50,000"),
        (Decimal(1_250_000), "₹12,50,000"),
        (Decimal(-8_000), "\u{2212}₹8,000"),
        (Decimal(0), "₹0"),
    ])
    func rupees(amount: Decimal, expected: String) {
        #expect(MoneyFormat.rupees(amount) == expected)
    }

    @Test("Signed rupees")
    func signed() {
        #expect(MoneyFormat.signedRupees(50_000) == "+₹50,000")
        #expect(MoneyFormat.signedRupees(-4_857) == "\u{2212}₹4,857")
    }

    @Test("Percentages")
    func percent() {
        #expect(PercentFormat.percent(62.5) == "62.5%")
        #expect(PercentFormat.percent(60) == "60%")
    }

    @Test("Months and History dates")
    func dates() {
        #expect(DateFormat.month(YearMonth(year: 2030, month: 9)) == "Sep 2030")
        let calendar = Fixture.calendar
        #expect(DateFormat.day(DemoScenario.date(day: 1), relativeTo: DemoScenario.date(day: 5), calendar: calendar) == "1 Oct")
        #expect(DateFormat.time(DemoScenario.date(day: 5), calendar: calendar) == "7:42 pm")
    }

    @Test("History rows read like the mockups")
    func historyText() throws {
        let ledger = Fixture.ledger(.afterTransfer)
        let opening = ledger.history[0]
        let credit = ledger.history[1]
        let transfer = ledger.history[2]
        #expect(LedgerText.historyDetail(opening, in: ledger) == "₹1,00,000 · Car ₹60,000 · Emergency ₹40,000")
        #expect(LedgerText.historyTitle(credit, in: ledger) == "New credit · Custom split")
        #expect(LedgerText.historyDetail(credit, in: ledger) == "₹1,00,000 → ₹1,50,000 · +₹50,000")
        #expect(LedgerText.historyDetail(transfer, in: ledger) == "Emergency → Car · ₹5,000")
    }
}

@Suite("Mock bank")
struct MockBankTests {
    private let accounts = DemoProfile.makeAccounts()

    @Test("First read is the opening balance, then the demo script, then unchanged")
    func script() async throws {
        let bank = MockBank(accounts: accounts)
        let savings = accounts[0]
        #expect(try await bank.fetchBalance(of: savings) == 100_000)
        #expect(try await bank.fetchBalance(of: savings) == 150_000)
        #expect(try await bank.fetchBalance(of: savings) == 170_000)
        #expect(try await bank.fetchBalance(of: savings) == 170_000)
    }

    @Test("A chosen next change applies once")
    func override() async throws {
        let bank = MockBank(accounts: accounts)
        let savings = accounts[0]
        _ = try await bank.fetchBalance(of: savings)
        await bank.setNextChange(.withdrawal8k)
        #expect(try await bank.fetchBalance(of: savings) == 92_000)
        #expect(await bank.currentNextChange() == .scripted)
    }

    @Test("PIN 000000 is wrong; accounts on other UPI apps cannot be checked")
    func pin() async throws {
        let bank = MockBank(accounts: accounts)
        await #expect(throws: BalanceServiceError.incorrectPIN) {
            try await bank.checkBalance(of: accounts[0], pin: "000000")
        }
        await #expect(throws: BalanceServiceError.notLinkedInPaytm) {
            try await bank.checkBalance(of: accounts[1], pin: "123456")
        }
        #expect(try await bank.checkBalance(of: accounts[0], pin: "123456") == 100_000)
    }

    @Test("Typed amounts keep the mock in step")
    func manualChange() async throws {
        let bank = MockBank(accounts: accounts, script: [])
        let savings = accounts[0]
        await bank.setBalance(100_000, for: savings)
        await bank.recordManualChange(20_000, for: savings)
        #expect(try await bank.fetchBalance(of: savings) == 120_000)
    }
}
