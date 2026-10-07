import Foundation

/// Reasons the rule engine refuses a change. The UI disables controls first; these are the backstop.
enum LedgerError: Error, Hashable, Sendable {
    case noDedicatedAccount
    case setupAlreadyComplete
    case setupIncomplete
    case noGoals
    case invalidGoal(GoalDraft.Issue)
    case goalNotFound
    case splitIncomplete
    case splitHasUnknownGoal
    case nonPositiveAmount
    case entryAlreadyOpen
    case entryNotOpen
    case splitAlreadyChanged
    case sameGoal
    case insufficientSavings
    case lastGoalNeedsReceiver
    case withdrawalExceedsSavings
    case reductionExceedsSaving
}
