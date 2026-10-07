import SwiftUI

/// 3a / 4b·2 · The opening balance, read automatically or with the UPI PIN.
struct Screen03aBalanceReadView: View {
    let source: HistoryEntry.Source

    @Environment(LedgerStore.self) private var store
    @Environment(Router.self) private var router

    var body: some View {
        PiScreen {
            PiNavBar(title: "Balance", showsBack: false, trailing: .tag("Step 2 of 3", .step))
        } content: {
            PiCard {
                PiSuccessBlock(
                    title: source == .fetched ? Text("Balance read automatically") : Text("Balance fetched"),
                    amount: MoneyFormat.rupees(store.setup.openingBalance),
                    caption: Text(verbatim: caption)
                )
            }
        } dock: {
            Button("Continue") {
                router.setupPath.append(.goalChat)
            }
            .buttonStyle(.piPrimary)
        }
    }

    private var caption: String {
        guard let account = store.dedicatedAccount else { return "" }
        return source == .fetched ? account.displayName : account.bankLabel
    }
}

#Preview {
    let store = LedgerStore.preview()
    store.setup.openingBalance = 100_000
    return NavigationStack {
        Screen03aBalanceReadView(source: .fetched)
    }
    .environment(store)
    .environment(Router())
}
