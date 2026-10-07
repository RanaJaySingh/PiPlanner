import SwiftUI

/// 18 / 18a · Withdrawal. Reductions must equal the shortfall and no goal goes below ₹0.
struct Screen18WithdrawalView: View {
    @Environment(LedgerStore.self) private var store
    @Environment(Router.self) private var router
    @State private var model: WithdrawalViewModel
    @State private var isSaving = false

    init(store: LedgerStore, request: WithdrawalRequest) {
        _model = State(initialValue: WithdrawalViewModel(store: store, request: request))
    }

    var body: some View {
        PiScreen {
            PiNavBar(title: "Withdrawal")
        } content: {
            PiCard {
                PiStatement(Text("Your savings balance went down by \(MoneyFormat.rupees(model.request.amount))."), isWarning: true)
                PiBodyText("Choose which goals it comes from.")
                VStack(spacing: 0) {
                    ForEach(model.split.shares) { share in
                        PiSplitRow(
                            name: LedgerText.goalName(share.goalID, in: model.ledger),
                            detail: Text(verbatim: MoneyFormat.rupees(model.reduction(for: share.goalID))),
                            detailTone: .warning,
                            trailing: .percent(Binding(
                                get: { model.split[share.goalID] },
                                set: { model.split[share.goalID] = $0 }
                            ))
                        )
                    }
                }
                PiTotalLine(total: model.split.total)
                if let message = model.validationMessage {
                    PiErrorLine(text: Text(verbatim: message))
                }
            }
        } dock: {
            Button("Save and lock", systemImage: PiIcon.lock) {
                Task { await save() }
            }
            .buttonStyle(.piPrimary)
            .disabled(!model.canSave || isSaving)
        }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        do {
            try await model.save()
            router.finish(showing: .history)
        } catch {
            store.showToast(userMessage(for: error))
        }
    }
}

#Preview {
    let store = LedgerStore.preview(stage: .afterTransfer)
    return NavigationStack {
        Screen18WithdrawalView(store: store, request: WithdrawalRequest(amount: 8_000, source: .fetched, fetchedBalance: 142_000))
    }
    .environment(store)
    .environment(Router())
}
