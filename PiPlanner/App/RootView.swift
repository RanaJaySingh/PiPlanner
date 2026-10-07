import SwiftUI

/// Setup until the opening split is locked, then the main tabs.
struct RootView: View {
    @Environment(LedgerStore.self) private var store

    var body: some View {
        @Bindable var store = store
        Group {
            if store.ledger.hasCompletedSetup {
                MainView()
                    .transition(.opacity)
            } else {
                SetupFlowView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: store.ledger.hasCompletedSetup)
        .piToast($store.toastMessage)
    }
}

/// Screens 1–8: a one-time stack.
struct SetupFlowView: View {
    @Environment(LedgerStore.self) private var store
    @Environment(Router.self) private var router

    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.setupPath) {
            Screen01WelcomeView()
                .navigationDestination(for: SetupRoute.self) { route in
                    destination(for: route)
                }
        }
        .sheet(item: $router.setupSheet) { sheet in
            switch sheet {
            case .consent:
                Screen03ConsentSheet(context: .setup)
            case let .updateBalance(notice):
                Screen04UpdateBalanceSheet(context: .setup, notice: notice)
            }
        }
    }

    @ViewBuilder
    private func destination(for route: SetupRoute) -> some View {
        switch route {
        case .accounts:
            Screen02AccountsView()
        case let .balanceRead(source):
            Screen03aBalanceReadView(source: source)
        case .manualOpening:
            Screen04aAmountEntryView(kind: .opening)
        case .pin:
            Screen04bPINView(purpose: .opening)
        case .goalChat:
            Screen05GoalChatView(store: store)
        case let .goalForm(request):
            Screen06GoalFormView(store: store, request: request)
        case .openingSplit:
            Screen08OpeningSplitView()
        }
    }
}

#Preview("Setup") {
    RootView()
        .environment(LedgerStore.preview())
        .environment(Router())
}

#Preview("Main") {
    RootView()
        .environment(LedgerStore.preview(stage: .afterCustomCredit))
        .environment(Router())
}
