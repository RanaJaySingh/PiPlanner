import Foundation
import Observation

/// Why the Update balance sheet reopened with a message (4c, 4e).
enum UpdateBalanceNotice: Hashable {
    case notLinkedInPaytm
    case incorrectPIN
}

/// What a Goal form creates or edits.
struct GoalFormRequest: Hashable {
    enum Mode: Hashable {
        /// Setup: the draft goes back to the Goal chat.
        case setup
        /// Goals tab or Ask: starts at ₹0 and reopens the standing split.
        case standalone
        /// From an open History entry: joins this amount's split (6c).
        case onEntry
        /// From the delete screen: receives part of the released saving.
        case onDeletion(of: Goal.ID)
        /// Edit an existing goal; held until the next entry (6e, 13g).
        case edit(Goal.ID)
    }

    var mode: Mode
    /// Pre-filled values, e.g. from a Grok proposal.
    var draft: GoalDraft?
}

struct TransferRequest: Hashable {
    var fromGoalID: Goal.ID?
    var toGoalID: Goal.ID?
    var amount: Decimal = 0
}

struct WithdrawalRequest: Hashable {
    let amount: Decimal
    let source: HistoryEntry.Source
    let fetchedBalance: Decimal?
}

enum AmountEntryKind: Hashable {
    /// 11b "How much did you add?"
    case added
    /// 18c "How much did you take out?"
    case withdrawn
}

enum SetupRoute: Hashable {
    case accounts
    /// 3a or 4b·2, depending on how the balance was read.
    case balanceRead(HistoryEntry.Source)
    case manualOpening
    case pin
    case goalChat
    case goalForm(GoalFormRequest)
    case openingSplit
}

enum SetupSheet: Hashable, Identifiable {
    case consent
    case updateBalance(UpdateBalanceNotice?)

    var id: Self { self }
}

enum MainTab: Hashable, CaseIterable {
    case goals
    case history
    case ask
}

enum MainRoute: Hashable {
    case entry(HistoryEntry.ID)
    case goalDetail(Goal.ID)
    case goalForm(GoalFormRequest)
    case transfer(TransferRequest)
    case deleteGoal(Goal.ID)
    case amountEntry(AmountEntryKind)
    case pin
    case withdrawal(WithdrawalRequest)
    case settings
}

enum MainSheet: Hashable, Identifiable {
    case sync(SyncPreview)
    case updateBalance(UpdateBalanceNotice?)
    case standingSplit
    case consent

    var id: String {
        switch self {
        case let .sync(preview): "sync-\(preview.id)"
        case let .updateBalance(notice): "update-\(String(describing: notice))"
        case .standingSplit: "standing"
        case .consent: "consent"
        }
    }
}

/// Typed navigation state: one stack for setup, one per tab, and the sheets.
@MainActor
@Observable
final class Router {
    var setupPath: [SetupRoute] = []
    var setupSheet: SetupSheet?

    var selectedTab: MainTab = .goals
    var goalsPath: [MainRoute] = []
    var historyPath: [MainRoute] = []
    var askPath: [MainRoute] = []
    var mainSheet: MainSheet?

    func path(for tab: MainTab) -> [MainRoute] {
        switch tab {
        case .goals: goalsPath
        case .history: historyPath
        case .ask: askPath
        }
    }

    func setPath(_ path: [MainRoute], for tab: MainTab) {
        switch tab {
        case .goals: goalsPath = path
        case .history: historyPath = path
        case .ask: askPath = path
        }
    }

    func push(_ route: MainRoute) {
        setPath(path(for: selectedTab) + [route], for: selectedTab)
    }

    func pop() {
        setPath(Array(path(for: selectedTab).dropLast()), for: selectedTab)
    }

    /// Replaces the top screen, e.g. PIN → Sync sheet result, without stacking.
    func replaceTop(with route: MainRoute) {
        setPath(Array(path(for: selectedTab).dropLast()) + [route], for: selectedTab)
    }

    func popToRoot() {
        setPath([], for: selectedTab)
    }

    /// Jumps to a tab and shows `route` on top of its root.
    func show(_ route: MainRoute?, in tab: MainTab) {
        selectedTab = tab
        setPath(route.map { [$0] } ?? [], for: tab)
    }

    /// Ends a flow: clears the current stack and shows the root of `tab`, e.g. History after a transfer.
    func finish(showing tab: MainTab) {
        setPath([], for: selectedTab)
        selectedTab = tab
        setPath([], for: tab)
    }

    func reset() {
        setupPath = []
        setupSheet = nil
        selectedTab = .goals
        goalsPath = []
        historyPath = []
        askPath = []
        mainSheet = nil
    }
}
