import SwiftUI

/// 4a / 11b / 18c · A typed amount: the opening balance, money added, or money taken out.
struct Screen04aAmountEntryView: View {
    enum Kind {
        case opening
        case added
        case withdrawn
    }

    let kind: Kind

    @Environment(LedgerStore.self) private var store
    @Environment(Router.self) private var router
    @State private var amount: Decimal = 0
    @State private var isSubmitting = false

    var body: some View {
        PiScreen {
            switch kind {
            case .opening: PiNavBar(title: "Opening balance", trailing: .tag("Step 2 of 3", .step))
            case .added: PiNavBar(title: "Add money")
            case .withdrawn: PiNavBar(title: "Record withdrawal")
            }
        } content: {
            switch kind {
            case .opening: PiLargeTitle("How much is in this account?")
            case .added: PiLargeTitle("How much did you add?")
            case .withdrawn: PiLargeTitle("How much did you take out?")
            }
            PiCard {
                PiAmountField(amount: $amount)
                if let validationMessage {
                    PiErrorLine(text: Text(verbatim: validationMessage), isCentered: true)
                }
            }
        } dock: {
            Button("Continue") {
                Task { await submit() }
            }
            .buttonStyle(.piPrimary)
            .disabled(!canContinue)
            switch kind {
            case .opening:
                EmptyView()
            case .added:
                Button("Record a withdrawal") { router.replaceTop(with: .amountEntry(.withdrawn)) }
                    .buttonStyle(.piLink)
            case .withdrawn:
                Button("Record money added") { router.replaceTop(with: .amountEntry(.added)) }
                    .buttonStyle(.piLink)
            }
        }
    }

    private var validationMessage: String? {
        guard kind == .withdrawn, amount > store.ledger.assignedTotal else { return nil }
        return String(localized: "Your goals have \(MoneyFormat.rupees(store.ledger.assignedTotal)) saved.")
    }

    private var canContinue: Bool {
        amount > 0 && validationMessage == nil && !isSubmitting
    }

    private func submit() async {
        isSubmitting = true
        defer { isSubmitting = false }
        switch kind {
        case .opening:
            await store.setTypedOpeningBalance(amount)
            router.setupPath.append(.goalChat)
        case .added:
            do {
                let entryID = try await store.recordTypedCredit(amount)
                router.replaceTop(with: .entry(entryID))
            } catch {
                store.showToast(userMessage(for: error))
            }
        case .withdrawn:
            router.replaceTop(with: .withdrawal(WithdrawalRequest(amount: amount, source: .typed, fetchedBalance: nil)))
        }
    }
}

#Preview("4a") {
    NavigationStack {
        Screen04aAmountEntryView(kind: .opening)
    }
    .environment(LedgerStore.preview())
    .environment(Router())
}

#Preview("11b") {
    NavigationStack {
        Screen04aAmountEntryView(kind: .added)
    }
    .environment(LedgerStore.preview(stage: .afterOpening))
    .environment(Router())
}
