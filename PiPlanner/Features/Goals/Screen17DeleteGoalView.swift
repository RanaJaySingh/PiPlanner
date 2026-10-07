import SwiftUI

/// 17 / 17a–17e · Delete a goal and move its saving. One entry is written.
struct Screen17DeleteGoalView: View {
    @Environment(LedgerStore.self) private var store
    @Environment(Router.self) private var router
    @State private var model: DeleteGoalViewModel

    init(store: LedgerStore, goalID: Goal.ID) {
        _model = State(initialValue: DeleteGoalViewModel(store: store, goalID: goalID))
    }

    var body: some View {
        let released = MoneyFormat.rupees(model.released)
        PiScreen {
            PiNavBar(title: "Delete \(model.goalName)")
        } content: {
            PiCard {
                PiStatement(Text("This releases \(released)."))
                PiBodyText("Choose where it goes.")
                if model.hasReceivers {
                    VStack(spacing: 0) {
                        ForEach(model.split.shares) { share in
                            PiSplitRow(
                                name: LedgerText.goalName(share.goalID, in: model.ledger),
                                detail: Text(verbatim: MoneyFormat.rupees(model.amount(for: share.goalID))),
                                detailTone: .success,
                                trailing: .percent(Binding(
                                    get: { model.split[share.goalID] },
                                    set: { model.setPercent($0, for: share.goalID) }
                                ))
                            )
                        }
                    }
                } else {
                    PiWarningBanner(text: Text("Create a goal to receive this money."))
                }
                Button("+ Create a goal") {
                    router.push(.goalForm(GoalFormRequest(mode: .onDeletion(of: model.goalID))))
                }
                .buttonStyle(.piLink)
                if model.hasReceivers {
                    PiTotalLine(total: model.split.total)
                    if !model.isEdited, model.split.shares.count > 1 {
                        PiBodyText("Split equally. Change it once.")
                    }
                }
            }
            if let standing = model.standingAfterDeletion, model.split.shares.count > 1 {
                PiCard {
                    PiBodyText("New credits will then split")
                    PiStatement(Text(verbatim: standing))
                }
            }
        } dock: {
            Button("Delete and move \(released)", action: delete)
                .buttonStyle(.piDestructive)
                .disabled(!model.canDelete)
            Button("Cancel") { router.pop() }
                .buttonStyle(.piLink(.navy))
        }
        .onChange(of: store.ledger.activeGoalIDs) { model.goalsChanged() }
    }

    private func delete() {
        do {
            try model.delete()
            router.finish(showing: .history)
        } catch {
            store.showToast(userMessage(for: error))
        }
    }
}

#Preview("17") {
    let store = LedgerStore.preview(stage: .afterCustomCredit)
    return NavigationStack {
        Screen17DeleteGoalView(store: store, goalID: store.ledger.activeGoals[2].id)
    }
    .environment(store)
    .environment(Router())
}

#Preview("17e · only goal") {
    let store = LedgerStore.preview()
    return NavigationStack {
        Screen17DeleteGoalView(store: store, goalID: UUID())
    }
    .environment(store)
    .environment(Router())
}
