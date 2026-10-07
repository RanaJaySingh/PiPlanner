import SwiftUI

/// 2 · Accounts. Exactly one account must be dedicated savings before Continue.
struct Screen02AccountsView: View {
    @Environment(LedgerStore.self) private var store
    @Environment(Router.self) private var router

    var body: some View {
        PiScreen {
            PiNavBar(title: "Accounts", trailing: .tag("Step 1 of 3", .step))
        } content: {
            PiLargeTitle("Your accounts")
            PiBodyText("Pick one for dedicated savings.")
                .padding(.horizontal, 6)
            ForEach(store.ledger.accounts) { account in
                accountCard(account)
            }
        } dock: {
            Button("Continue") {
                router.setupSheet = .consent
            }
            .buttonStyle(.piPrimary)
            .disabled(store.dedicatedAccount == nil)
        }
    }

    private func accountCard(_ account: Account) -> some View {
        let isDedicated = account.role == .dedicatedSavings
        return PiCard {
            PiChoiceRow(
                icon: PiIcon.bank,
                iconStyle: isDedicated ? .navyTint : .neutral,
                title: Text(verbatim: MoneyFormat.rupees(account.mockBalance)),
                subtitle: Text(verbatim: account.displayName),
                titleIsAmount: true
            )
            PiToggleRow(title: Text("Dedicated savings"), isOn: Binding(
                get: { isDedicated },
                set: { isOn in
                    withAnimation(.snappy) {
                        store.markDedicated(isOn ? account.id : nil)
                    }
                }
            ))
            if !isDedicated {
                PiBodyText("Everyday spend. Not split across goals.")
            }
        }
    }
}

#Preview {
    NavigationStack {
        Screen02AccountsView()
    }
    .environment(LedgerStore.preview())
    .environment(Router())
}
