import Foundation

extension LedgerError {
    /// Shown as a toast. Controls are disabled before these can happen, so they are a backstop.
    var message: String {
        switch self {
        case .noDedicatedAccount: String(localized: "Pick one account for dedicated savings.")
        case .setupAlreadyComplete: String(localized: "Setup is already complete.")
        case .setupIncomplete: String(localized: "Finish setup first.")
        case .noGoals: String(localized: "Add at least one goal.")
        case .invalidGoal: String(localized: "Check the goal's name, target and dates.")
        case .goalNotFound: String(localized: "That goal no longer exists.")
        case .splitIncomplete: String(localized: "Percentages must add up to 100%.")
        case .splitHasUnknownGoal: String(localized: "The split names a goal that no longer exists.")
        case .nonPositiveAmount: String(localized: "Enter an amount above ₹0.")
        case .entryAlreadyOpen: String(localized: "Save the open History entry first.")
        case .entryNotOpen: String(localized: "This entry is already saved and locked.")
        case .splitAlreadyChanged: String(localized: "This split was already changed once.")
        case .sameGoal: String(localized: "Choose two different goals.")
        case .insufficientSavings: String(localized: "That goal does not have enough saved.")
        case .lastGoalNeedsReceiver: String(localized: "Create a goal to receive this money.")
        case .withdrawalExceedsSavings: String(localized: "The withdrawal is more than everything saved.")
        case .reductionExceedsSaving: String(localized: "No goal can go below ₹0.")
        }
    }
}

extension BalanceServiceError {
    var message: String {
        switch self {
        case .notLinkedInPaytm: String(localized: "This account is not linked in Paytm, so we can't check it. Enter the balance instead.")
        case .incorrectPIN: String(localized: "Incorrect PIN.")
        }
    }
}

/// A readable message for any error thrown by the store.
func userMessage(for error: any Error) -> String {
    switch error {
    case let error as LedgerError: error.message
    case let error as BalanceServiceError: error.message
    default: String(localized: "Something went wrong. Please try again.")
    }
}
