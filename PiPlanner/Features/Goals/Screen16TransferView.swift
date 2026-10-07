import SwiftUI

/// 16 / 16b · Transfer between goals. One transfer entry is written.
struct Screen16TransferView: View {
    @Environment(LedgerStore.self) private var store
    @Environment(Router.self) private var router
    @State private var model: TransferViewModel

    init(store: LedgerStore, request: TransferRequest) {
        _model = State(initialValue: TransferViewModel(store: store, request: request))
    }

    var body: some View {
        @Bindable var model = model
        PiScreen {
            PiNavBar(title: "Transfer", trailing: .icon(systemName: PiIcon.history, accessibilityLabel: "History") {
                router.finish(showing: .history)
            })
        } content: {
            PiCard {
                goalMenu(label: Text("From"), selection: model.fromGoal, onSelect: model.chooseFrom)
            }
            PiCard {
                goalMenu(label: Text("To"), selection: model.toGoal, onSelect: model.chooseTo)
            }
            PiCard {
                PiAmountField(amount: $model.amount)
                if let error = model.errorMessage {
                    PiErrorLine(text: Text(verbatim: error), isCentered: true)
                } else {
                    PiFlowLayout {
                        ForEach(TransferViewModel.quickAmounts, id: \.self) { value in
                            PiSuggestionChip(text: MoneyFormat.rupees(value)) { model.amount = value }
                        }
                    }
                }
            }
            if model.canConfirm, let from = model.fromGoal, let to = model.toGoal {
                PiCard(spacing: 0) {
                    PiSectionHeader(Text("After transfer"))
                    PiValueRow(
                        label: Text(verbatim: from.name),
                        value: Text(verbatim: "\(MoneyFormat.rupees(model.saved(from.id))) → \(MoneyFormat.rupees(model.saved(from.id) - model.amount))"),
                        tone: .warning
                    )
                    PiValueRow(
                        label: Text(verbatim: to.name),
                        value: Text(verbatim: "\(MoneyFormat.rupees(model.saved(to.id))) → \(MoneyFormat.rupees(model.saved(to.id) + model.amount))"),
                        tone: .success,
                        showsDivider: false
                    )
                }
            }
        } dock: {
            Button("Move \(MoneyFormat.rupees(model.amount))", action: confirm)
                .buttonStyle(.piPrimary)
                .disabled(!model.canConfirm)
        }
    }

    private func goalMenu(label: Text, selection: Goal?, onSelect: @escaping (Goal.ID) -> Void) -> some View {
        Menu {
            ForEach(model.goals) { goal in
                Button("\(goal.name) · \(MoneyFormat.rupees(model.saved(goal.id)))") { onSelect(goal.id) }
            }
        } label: {
            PiChoiceRow(
                icon: PiIcon.goal(named: selection?.name ?? ""),
                title: Text("\(MoneyFormat.rupees(model.saved(selection?.id))) saved"),
                subtitle: label + Text(verbatim: " · \(selection?.name ?? "")"),
                titleIsAmount: true,
                accessory: .chevron
            )
        }
        .buttonStyle(.plain)
    }

    private func confirm() {
        do {
            try model.confirm()
            router.finish(showing: .history)
        } catch {
            store.showToast(userMessage(for: error))
        }
    }
}

#Preview {
    let store = LedgerStore.preview(stage: .afterCustomCredit)
    let goals = store.ledger.activeGoals
    return NavigationStack {
        Screen16TransferView(store: store, request: TransferRequest(fromGoalID: goals[1].id, toGoalID: goals[0].id, amount: 5_000))
    }
    .environment(store)
    .environment(Router())
}
