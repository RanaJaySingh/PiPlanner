import Foundation

/// Rahul's demo, replayed through the engine to a given point. Used by previews and tests.
enum DemoScenario {
    enum Stage: CaseIterable {
        /// Fresh accounts, nothing set up.
        case welcome
        /// Opening split locked: Car ₹60,000, Emergency ₹40,000.
        case afterOpening
        /// Sync found ₹50,000; the entry is open with the 60/40 suggestion.
        case openCredit
        /// Vacation created on the entry and the 50/30/20 split saved and carried forward.
        case afterCustomCredit
        /// ₹5,000 moved from Emergency to Car.
        case afterTransfer
    }

    static let start = YearMonth(year: 2026, month: 10)

    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Kolkata") ?? .current
        calendar.locale = Locale(identifier: "en_IN")
        return calendar
    }()

    /// A date in October 2026, 7:42 pm by default.
    static func date(day: Int, hour: Int = 19, minute: Int = 42) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute)) ?? Date()
    }

    static var now: Date { date(day: 5) }

    static func ledger(at stage: Stage) -> Ledger {
        var ledger = DemoProfile.makeLedger()
        guard stage != .welcome else { return ledger }

        do {
            try ledger.setConsent(isOn: true)
            try ledger.completeSetup(goals: DemoProfile.goalDrafts(start: start), openingBalance: 100_000, source: .fetched, date: date(day: 1))
            guard stage != .afterOpening else { return ledger }

            let entryID = try ledger.beginCredit(amount: 50_000, source: .fetched, fetchedBalance: 150_000, date: date(day: 5))
            guard stage != .openCredit else { return ledger }

            let vacation = try ledger.createGoal(DemoProfile.vacationDraft(start: start), placement: .onOpenEntry)
            let ids = ledger.activeGoalIDs
            let split = Split([
                .init(goalID: ids[0], percent: 50),
                .init(goalID: ids[1], percent: 30),
                .init(goalID: vacation, percent: 20),
            ])
            try ledger.changeSplit(ofEntry: entryID, to: split, carryForward: true)
            try ledger.saveEntry(entryID)
            guard stage != .afterCustomCredit else { return ledger }

            try ledger.transfer(from: ids[1], to: ids[0], amount: 5_000, date: date(day: 5, hour: 20))
        } catch {
            assertionFailure("Demo scenario failed: \(error)")
        }
        return ledger
    }

    /// A bank that has already been read at `ledger`'s snapshot, with the credits of earlier stages used up.
    static func bank(for ledger: Ledger, at stage: Stage) -> MockBank {
        guard stage != .welcome, let account = ledger.dedicatedAccount, let snapshot = ledger.snapshot else {
            return MockBank(accounts: ledger.accounts)
        }
        let creditsUsed = stage == .afterOpening ? 0 : 1
        return MockBank(
            accounts: ledger.accounts,
            script: Array(MockBank.demoScript.dropFirst(creditsUsed)),
            alreadyRead: [account.id: snapshot]
        )
    }
}

extension LedgerStore {
    /// A store on the fixed demo clock with the offline Grok, for previews.
    static func preview(stage: DemoScenario.Stage = .welcome) -> LedgerStore {
        let ledger = DemoScenario.ledger(at: stage)
        let services = AppServices(
            clock: FixedClock(now: DemoScenario.now),
            calendar: DemoScenario.calendar,
            bank: DemoScenario.bank(for: ledger, at: stage),
            grok: GrokOrchestrator(provider: GrokClientProvider(settings: GrokSettings(suiteName: "com.piplanner.preview")))
        )
        return LedgerStore(
            services: services,
            ledger: ledger,
            grokSettings: GrokSettings(suiteName: "com.piplanner.preview"),
            lastBalanceUpdate: stage == .welcome ? nil : DemoScenario.now
        )
    }
}
