import Foundation

enum BalanceServiceError: Error, Hashable, Sendable {
    /// The account is on another UPI app, so Paytm cannot check it.
    case notLinkedInPaytm
    case incorrectPIN
}

/// Reads the dedicated account's balance. Production swaps the mock for an Account Aggregator read
/// (consent Yes) and Paytm's UPI balance enquiry (consent No, PIN each time).
protocol BalanceFetching: Sendable {
    /// Consent Yes: read without further steps.
    func fetchBalance(of account: Account) async throws -> Decimal
    /// Consent No, Balance sync: UPI PIN → Check balance → Fetch. Only for accounts linked in Paytm.
    func checkBalance(of account: Account, pin: String) async throws -> Decimal
}

protocol PINValidating: Sendable {
    func isValid(_ pin: String) -> Bool
}

/// The prototype's PIN pad is a labelled mock. Any six digits pass except 000000, which demos a wrong PIN.
struct DemoPINValidator: PINValidating {
    static let pinLength = 6

    func isValid(_ pin: String) -> Bool {
        pin.count == Self.pinLength && pin.allSatisfy(\.isNumber) && pin != String(repeating: "0", count: Self.pinLength)
    }
}
