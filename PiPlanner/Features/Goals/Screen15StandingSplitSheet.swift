import SwiftUI

/// 15 · Standing split: the suggestion for the next credit. Saved money stays where it is.
struct Screen15StandingSplitSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: Split
    private let store: LedgerStore

    init(store: LedgerStore) {
        self.store = store
        _draft = State(initialValue: store.ledger.standingSplit)
    }

    var body: some View {
        PiSheet {
            PiSheetHeader(Text("Standing split")) { dismiss() }
            PiBodyText("Used for the next credit. Saved money stays where it is.")
            VStack(spacing: 0) {
                ForEach(draft.shares) { share in
                    PiSplitRow(
                        name: LedgerText.goalName(share.goalID, in: store.ledger),
                        detail: Text(verbatim: example(for: share.goalID)),
                        trailing: .percent(Binding(
                            get: { draft[share.goalID] },
                            set: { draft[share.goalID] = $0 }
                        ))
                    )
                }
            }
            PiTotalLine(total: draft.total)
            Button("Save", action: save)
                .buttonStyle(.piPrimary)
                .disabled(!draft.isComplete)
        }
    }

    /// "₹22,500 of every ₹50,000"
    private func example(for goalID: UUID) -> String {
        let reference = store.referenceCreditAmount
        let part = (reference * draft[goalID] / 100).rounded()
        return String(localized: "\(MoneyFormat.rupees(part)) of every \(MoneyFormat.rupees(reference))")
    }

    private func save() {
        do {
            try store.updateStandingSplit(draft)
            dismiss()
        } catch {
            store.showToast(userMessage(for: error))
        }
    }
}

#Preview {
    let store = LedgerStore.preview(stage: .afterCustomCredit)
    return Color.clear.sheet(isPresented: .constant(true)) {
        Screen15StandingSplitSheet(store: store)
    }
    .environment(store)
}
