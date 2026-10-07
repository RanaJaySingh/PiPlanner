import Foundation

/// A linked bank account. Exactly one may be the dedicated savings account.
struct Account: Identifiable, Hashable, Codable, Sendable {
    enum Role: String, Hashable, Codable, Sendable {
        case dedicatedSavings
        case spending
    }

    let id: UUID
    /// "HDFC"
    let bank: String
    /// "Savings" or "Spending"
    let kind: String
    /// "••4821"
    let maskedNumber: String
    var role: Role
    var mockBalance: Decimal
    /// `false` means the account lives on another UPI app, so only manual entry works.
    var linkedInPaytm: Bool

    /// "Savings · HDFC ••4821"
    var displayName: String { "\(kind) · \(bank) \(maskedNumber)" }

    /// "HDFC Bank ••4821"
    var bankLabel: String { "\(bank) Bank \(maskedNumber)" }

    /// "HDFC ••4821"
    var shortLabel: String { "\(bank) \(maskedNumber)" }
}

/// The customer's answer to "Allow PiPlanner to check this balance?".
/// Off means every update asks: Manually, or Balance sync.
struct Consent: Hashable, Codable, Sendable {
    var isOn: Bool
    var acceptedScope: String
}
