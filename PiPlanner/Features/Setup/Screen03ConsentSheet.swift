import SwiftUI

/// 3 / 20b · "Allow PiPlanner to check this balance?"
struct Screen03ConsentSheet: View {
    enum Context {
        /// After Accounts: Yes reads the opening balance, No offers Manually or Balance sync.
        case setup
        /// From Settings: Yes turns automatic updates on, No leaves them off.
        case settings
    }

    let context: Context

    @Environment(LedgerStore.self) private var store
    @Environment(Router.self) private var router

    var body: some View {
        PiSheet {
            PiSheetHeader(Text("Allow PiPlanner to check this balance?"))
            if let account = store.dedicatedAccount {
                PiBodyText(Text(verbatim: account.displayName))
            }
            VStack(alignment: .leading, spacing: 10) {
                PiCheckRow(text: Text("Reads only this balance"))
                PiCheckRow(text: Text("Stores the last balance to find what is new"))
                PiCheckRow(text: Text("Never sends statements, payees, UPI ids or account numbers to Grok"))
                PiCheckRow(text: Text("Change it any time in Settings"))
            }
            .padding(.vertical, PiSpacing.xs)
            VStack(spacing: PiSpacing.s) {
                Button("Yes, update automatically", action: accept)
                    .buttonStyle(.piPrimary)
                Button("No, I'll update it myself", action: decline)
                    .buttonStyle(.piSecondary)
            }
        }
    }

    private func accept() {
        switch context {
        case .setup:
            do {
                try store.answerConsent(isOn: true)
            } catch {
                store.showToast(userMessage(for: error))
                return
            }
            router.setupSheet = nil
            Task {
                do {
                    _ = try await store.fetchOpeningBalance()
                    router.setupPath.append(.balanceRead(.fetched))
                } catch {
                    store.showToast(userMessage(for: error))
                }
            }
        case .settings:
            do {
                try store.setAutomaticUpdates(true)
            } catch {
                store.showToast(userMessage(for: error))
            }
            router.mainSheet = nil
        }
    }

    private func decline() {
        switch context {
        case .setup:
            do {
                try store.answerConsent(isOn: false)
                router.setupSheet = .updateBalance(nil)
            } catch {
                store.showToast(userMessage(for: error))
            }
        case .settings:
            router.mainSheet = nil
        }
    }
}

#Preview {
    Color.clear.sheet(isPresented: .constant(true)) {
        Screen03ConsentSheet(context: .setup)
    }
    .environment(LedgerStore.preview())
    .environment(Router())
}
