import SwiftUI

/// Goals, History and Ask, each with its own stack. The tab bar shows only on tab roots.
struct MainView: View {
    @Environment(LedgerStore.self) private var store
    @Environment(Router.self) private var router
    @State private var isKeyboardVisible = false

    private let tabs: [PiTabBar<MainTab>.Item] = [
        .init(tab: .goals, title: "Goals", icon: PiIcon.goals),
        .init(tab: .history, title: "History", icon: PiIcon.history),
        .init(tab: .ask, title: "Ask", icon: PiIcon.ask),
    ]

    var body: some View {
        @Bindable var router = router
        // A TabView keeps each stack alive and hides the others from VoiceOver; PiTabBar replaces its bar.
        TabView(selection: $router.selectedTab) {
            ForEach(MainTab.allCases, id: \.self) { tab in
                tabStack(for: tab)
                    .toolbar(.hidden, for: .tabBar)
                    .tag(tab)
            }
        }
        .sheet(item: $router.mainSheet) { sheet in
            switch sheet {
            case let .sync(preview):
                Screen10SyncSheet(preview: preview)
            case let .updateBalance(notice):
                Screen04UpdateBalanceSheet(context: .main, notice: notice)
            case .standingSplit:
                Screen15StandingSplitSheet(store: store)
            case .consent:
                Screen03ConsentSheet(context: .settings)
            }
        }
    }

    private func tabStack(for tab: MainTab) -> some View {
        NavigationStack(path: Binding(
            get: { router.path(for: tab) },
            set: { router.setPath($0, for: tab) }
        )) {
            root(for: tab)
                // On the root only, so pushed screens hide the bar. An inset outside the stack does not reach its screens.
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    // Hidden while typing so it does not ride above the keyboard.
                    if !isKeyboardVisible {
                        PiTabBar(items: tabs, selection: Binding(
                            get: { router.selectedTab },
                            set: { router.selectedTab = $0 }
                        ))
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                    isKeyboardVisible = true
                }
                .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                    isKeyboardVisible = false
                }
                .navigationDestination(for: MainRoute.self) { route in
                    MainDestination(route: route)
                }
        }
    }

    @ViewBuilder
    private func root(for tab: MainTab) -> some View {
        switch tab {
        case .goals: Screen09GoalsView()
        case .history: Screen12HistoryView()
        case .ask: Screen19AskView(store: store)
        }
    }
}

/// Builds the screen for a pushed main route.
struct MainDestination: View {
    let route: MainRoute

    @Environment(LedgerStore.self) private var store

    var body: some View {
        switch route {
        case let .entry(id):
            Screen13EntryView(store: store, entryID: id)
        case let .goalDetail(id):
            Screen14GoalDetailView(goalID: id)
        case let .goalForm(request):
            Screen06GoalFormView(store: store, request: request)
        case let .transfer(request):
            Screen16TransferView(store: store, request: request)
        case let .deleteGoal(id):
            Screen17DeleteGoalView(store: store, goalID: id)
        case let .amountEntry(kind):
            Screen04aAmountEntryView(kind: kind == .added ? .added : .withdrawn)
        case .pin:
            Screen04bPINView(purpose: .sync)
        case let .withdrawal(request):
            Screen18WithdrawalView(store: store, request: request)
        case .settings:
            Screen20SettingsView()
        }
    }
}
