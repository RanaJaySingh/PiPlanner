import Foundation

/// In-memory stand-in for the bank. The first read of an account returns its opening balance;
/// every later read first applies the next scripted change, so Sync finds the demo credit.
actor MockBank: BalanceFetching {
    /// What the next balance read should find. Chosen from Settings during a demo.
    enum NextChange: String, CaseIterable, Hashable, Sendable {
        case scripted
        case credit50k
        case credit20k
        case unchanged
        case withdrawal8k

        var delta: Decimal? {
            switch self {
            case .scripted: nil
            case .credit50k: 50_000
            case .credit20k: 20_000
            case .unchanged: 0
            case .withdrawal8k: -8_000
            }
        }
    }

    static let demoScript: [Decimal] = [50_000, 20_000]

    private var balances: [UUID: Decimal] = [:]
    private var openedAccounts: Set<UUID> = []
    private var script: [Decimal]
    private var nextChange: NextChange = .scripted
    private let pinValidator: any PINValidating

    /// - Parameter alreadyRead: Balances that count as read before, so their next read applies the script.
    init(
        accounts: [Account],
        script: [Decimal] = MockBank.demoScript,
        alreadyRead: [UUID: Decimal] = [:],
        pinValidator: any PINValidating = DemoPINValidator()
    ) {
        self.script = script
        self.pinValidator = pinValidator
        balances = Dictionary(uniqueKeysWithValues: accounts.map { ($0.id, $0.mockBalance) })
            .merging(alreadyRead) { _, read in read }
        openedAccounts = Set(alreadyRead.keys)
    }

    func reset(accounts: [Account], script: [Decimal] = MockBank.demoScript) {
        balances = Dictionary(uniqueKeysWithValues: accounts.map { ($0.id, $0.mockBalance) })
        openedAccounts = []
        self.script = script
        nextChange = .scripted
    }

    func setNextChange(_ change: NextChange) {
        nextChange = change
    }

    func currentNextChange() -> NextChange {
        nextChange
    }

    /// Keeps the mock in step with amounts the customer typed, so a later automatic read agrees.
    func recordManualChange(_ delta: Decimal, for account: Account) {
        balances[account.id, default: account.mockBalance] += delta
        openedAccounts.insert(account.id)
    }

    /// Sets the balance outright, e.g. to the opening balance the customer typed.
    func setBalance(_ balance: Decimal, for account: Account) {
        balances[account.id] = balance
        openedAccounts.insert(account.id)
    }

    func fetchBalance(of account: Account) async throws -> Decimal {
        read(account)
    }

    func checkBalance(of account: Account, pin: String) async throws -> Decimal {
        guard account.linkedInPaytm else { throw BalanceServiceError.notLinkedInPaytm }
        guard pinValidator.isValid(pin) else { throw BalanceServiceError.incorrectPIN }
        return read(account)
    }

    private func read(_ account: Account) -> Decimal {
        let current = balances[account.id, default: account.mockBalance]
        guard openedAccounts.contains(account.id) else {
            openedAccounts.insert(account.id)
            return current
        }
        let delta: Decimal
        if let override = nextChange.delta {
            delta = override
            nextChange = .scripted
        } else {
            delta = script.isEmpty ? 0 : script.removeFirst()
        }
        let updated = current + delta
        balances[account.id] = updated
        return updated
    }
}
