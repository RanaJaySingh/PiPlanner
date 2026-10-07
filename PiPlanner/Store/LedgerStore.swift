import Foundation
import Observation

/// The single source of truth for the UI. Owns the ledger value and applies every change atomically:
/// copy, mutate, then assign, so a thrown rule leaves the published state untouched.
@MainActor
@Observable
final class LedgerStore {
    private(set) var ledger: Ledger
    var setup = SetupDraft()
    var askThread = ChatThread()
    private(set) var lastBalanceUpdate: Date?
    var toastMessage: String?
    /// One-time split handed from an Ask proposal to the open History entry.
    var proposedEntrySplit: Split?
    private(set) var grokMode: GrokMode
    private(set) var hasGrokAPIKey: Bool
    private(set) var nextBalanceChange: MockBank.NextChange = .scripted

    let services: AppServices
    private let grokSettings: GrokSettings

    init(
        services: AppServices,
        ledger: Ledger = DemoProfile.makeLedger(),
        grokSettings: GrokSettings = .standard,
        lastBalanceUpdate: Date? = nil
    ) {
        self.services = services
        self.ledger = ledger
        self.grokSettings = grokSettings
        self.lastBalanceUpdate = lastBalanceUpdate
        grokMode = grokSettings.mode
        hasGrokAPIKey = grokSettings.apiKey != nil
    }

    // MARK: - Environment

    var now: Date { services.clock.now }
    var calendar: Calendar { services.calendar }
    var currentMonth: YearMonth { YearMonth(date: now, calendar: calendar) }
    var isAutomatic: Bool { ledger.consent?.isOn == true }
    var dedicatedAccount: Account? { ledger.dedicatedAccount }
    var isGrokAvailable: Bool {
        switch grokMode {
        case .mock: true
        case .live: hasGrokAPIKey
        case .off: false
        }
    }

    /// The amount used for "₹7,500 of every ₹50,000 credit": the latest credit, or ₹50,000 before any.
    var referenceCreditAmount: Decimal {
        ledger.history.last { $0.kind == .credit }?.amount ?? 50_000
    }

    func progress(of goalID: UUID) -> GoalProgress? {
        ledger.progress(of: goalID, asOf: currentMonth, calendar: calendar)
    }

    // MARK: - Atomic mutation

    @discardableResult
    private func mutate<T>(_ body: (inout Ledger) throws -> T) throws -> T {
        var copy = ledger
        let result = try body(&copy)
        ledger = copy
        return result
    }

    // MARK: - Setup

    func markDedicated(_ accountID: UUID?) {
        ledger.markDedicated(accountID)
    }

    func answerConsent(isOn: Bool) throws {
        try mutate { try $0.setConsent(isOn: isOn) }
    }

    /// Consent Yes during setup: reads the opening balance automatically (3a).
    func fetchOpeningBalance() async throws -> Decimal {
        guard let account = dedicatedAccount else { throw LedgerError.noDedicatedAccount }
        let balance = try await services.balance.fetchBalance(of: account)
        setup.openingBalance = balance
        setup.balanceSource = .fetched
        return balance
    }

    /// Consent No, Balance sync during setup (4b → 4b·2).
    func checkOpeningBalance(pin: String) async throws -> Decimal {
        guard let account = dedicatedAccount else { throw LedgerError.noDedicatedAccount }
        let balance = try await services.balance.checkBalance(of: account, pin: pin)
        setup.openingBalance = balance
        setup.balanceSource = .pinCheck
        return balance
    }

    /// Consent No, Manually during setup (4a).
    func setTypedOpeningBalance(_ amount: Decimal) async {
        setup.openingBalance = amount
        setup.balanceSource = .typed
        if let account = dedicatedAccount {
            await services.bank.setBalance(amount, for: account)
        }
    }

    /// Locks the opening split and writes the opening History entry.
    func completeSetup() throws {
        let drafts = setup.goals
        try mutate {
            try $0.completeSetup(goals: drafts, openingBalance: setup.openingBalance, source: setup.balanceSource, date: now)
        }
        lastBalanceUpdate = now
    }

    // MARK: - Balance updates

    /// Sync (consent Yes): reads the balance and compares it with the snapshot.
    func syncBalance() async throws -> BalanceReading {
        guard let account = dedicatedAccount else { throw LedgerError.noDedicatedAccount }
        let fetched = try await services.balance.fetchBalance(of: account)
        await refreshNextChange()
        return try reading(for: fetched, source: .fetched)
    }

    /// Balance sync with UPI PIN (consent No).
    func checkBalance(pin: String) async throws -> BalanceReading {
        guard let account = dedicatedAccount else { throw LedgerError.noDedicatedAccount }
        let fetched = try await services.balance.checkBalance(of: account, pin: pin)
        await refreshNextChange()
        return try reading(for: fetched, source: .pinCheck)
    }

    private func reading(for fetched: Decimal, source: HistoryEntry.Source) throws -> BalanceReading {
        lastBalanceUpdate = now
        guard let previous = ledger.snapshot else { throw LedgerError.setupIncomplete }
        if try ledger.balanceChange(forFetched: fetched) == .unchanged {
            return .unchanged
        }
        let lastRead = ledger.history.last { $0.kind == .credit || $0.kind == .withdrawal || $0.kind == .opening }
        return .changed(SyncPreview(previous: previous, fetched: fetched, source: source, isCatchUp: lastRead?.source == .typed))
    }

    /// Continue on the Sync sheet for a higher balance: writes the open entry.
    func beginCredit(from preview: SyncPreview) throws -> HistoryEntry.ID {
        try mutate {
            try $0.beginCredit(amount: preview.delta, source: preview.source, fetchedBalance: preview.fetched, date: now)
        }
    }

    /// 11b: "How much did you add?"
    func recordTypedCredit(_ amount: Decimal) async throws -> HistoryEntry.ID {
        let id = try mutate { try $0.beginCredit(amount: amount, source: .typed, fetchedBalance: nil, date: now) }
        lastBalanceUpdate = now
        if let account = dedicatedAccount {
            await services.bank.recordManualChange(amount, for: account)
        }
        return id
    }

    func recordWithdrawal(amount: Decimal, split: Split, source: HistoryEntry.Source, fetchedBalance: Decimal?) async throws {
        try mutate {
            try $0.recordWithdrawal(amount: amount, split: split, source: source, fetchedBalance: fetchedBalance, date: now)
        }
        lastBalanceUpdate = now
        if source == .typed, let account = dedicatedAccount {
            await services.bank.recordManualChange(-amount, for: account)
        }
    }

    // MARK: - History entries

    /// Save and lock. A custom split is applied first; it can only be set once per entry.
    func saveEntry(_ entryID: HistoryEntry.ID, customSplit: Split?, carryForward: Bool) throws {
        try mutate { ledger in
            if let customSplit {
                try ledger.changeSplit(ofEntry: entryID, to: customSplit, carryForward: carryForward)
            }
            try ledger.saveEntry(entryID)
        }
    }

    // MARK: - Goals

    @discardableResult
    func createGoal(_ draft: GoalDraft, placement: Ledger.GoalPlacement) throws -> Goal.ID {
        try mutate { try $0.createGoal(draft, placement: placement) }
    }

    func stageEdit(_ draft: GoalDraft, for goalID: Goal.ID) throws {
        try mutate { try $0.stageEdit(draft.edit, for: goalID) }
    }

    func updateStandingSplit(_ split: Split) throws {
        try mutate { try $0.updateStandingSplit(split) }
    }

    func transfer(from: Goal.ID, to: Goal.ID, amount: Decimal) throws {
        try mutate { try $0.transfer(from: from, to: to, amount: amount, date: now) }
    }

    func deleteGoal(_ goalID: Goal.ID, redistribution: Split) throws {
        try mutate { try $0.deleteGoal(goalID, redistribution: redistribution, date: now) }
    }

    /// The standing split that deleting `goalID` would leave, computed on a copy of the ledger.
    func standingSplitAfterDeleting(_ goalID: Goal.ID, redistribution: Split) -> Split? {
        var copy = ledger
        guard (try? copy.deleteGoal(goalID, redistribution: redistribution, date: now)) != nil else { return nil }
        return copy.standingSplit
    }

    // MARK: - Settings

    func setAutomaticUpdates(_ isOn: Bool) throws {
        try mutate { try $0.setConsent(isOn: isOn) }
    }

    func setLinkedInPaytm(_ isLinked: Bool, accountID: UUID) {
        ledger.setLinkedInPaytm(isLinked, accountID: accountID)
    }

    func setNextBalanceChange(_ change: MockBank.NextChange) async {
        await services.bank.setNextChange(change)
        nextBalanceChange = change
    }

    private func refreshNextChange() async {
        nextBalanceChange = await services.bank.currentNextChange()
    }

    func setGrokMode(_ mode: GrokMode) {
        grokSettings.mode = mode
        grokMode = mode
    }

    func setGrokAPIKey(_ key: String?) {
        let trimmed = key?.trimmingCharacters(in: .whitespacesAndNewlines)
        grokSettings.apiKey = trimmed?.isEmpty == false ? trimmed : nil
        hasGrokAPIKey = grokSettings.apiKey != nil
    }

    /// Clears goals and history and restores Rahul's accounts. Grok preferences are kept.
    func resetDemo() async {
        let fresh = DemoProfile.makeLedger()
        ledger = fresh
        setup = SetupDraft()
        askThread = ChatThread()
        lastBalanceUpdate = nil
        toastMessage = nil
        proposedEntrySplit = nil
        await services.bank.reset(accounts: fresh.accounts)
        nextBalanceChange = .scripted
    }

    // MARK: - Grok

    func askGrok(_ utterance: String, surface: GrokSurface, followUpCount: Int) async -> GrokOutcome {
        await services.grok.respond(
            to: utterance,
            surface: surface,
            ledger: ledger,
            setupDrafts: surface == .goalSetup ? setup.goals : [],
            readyToSplit: surface == .goalSetup ? setup.openingBalance : nil,
            followUpCount: followUpCount,
            asOf: currentMonth,
            calendar: calendar
        )
    }

    func grokContext() -> GrokContext {
        GrokOrchestrator.context(ledger: ledger, asOf: currentMonth, calendar: calendar)
    }

    func showToast(_ message: String) {
        toastMessage = message
    }
}
