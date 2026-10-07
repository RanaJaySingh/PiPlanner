import SwiftUI

/// 8 / 8b · Opening split. Locking writes the opening History entry and opens the Goals tab.
struct Screen08OpeningSplitView: View {
    @Environment(LedgerStore.self) private var store
    @Environment(Router.self) private var router

    var body: some View {
        let setup = store.setup
        PiScreen {
            PiNavBar(title: "Opening split", trailing: .tag("Step 3 of 3", .step))
        } content: {
            PiCard(style: .hero, spacing: 6) {
                PiBodyText(Text(verbatim: String(localized: "Dedicated savings · \(store.dedicatedAccount?.shortLabel ?? "")")))
                PiBalanceText(amount: MoneyFormat.rupees(setup.openingBalance))
            }
            PiCard {
                PiSectionHeader(Text("Split \(MoneyFormat.rupees(setup.openingBalance))"))
                ForEach(setup.goals) { draft in
                    PiSplitRow(
                        name: draft.trimmedName,
                        detail: Text(verbatim: detail(for: draft)),
                        detailTone: .success,
                        trailing: setup.goals.count == 1 ? .fixed(PercentFormat.percent(100)) : .percent(percentBinding(for: draft.id)),
                        showsDivider: draft.id != setup.goals.last?.id
                    )
                }
                if setup.goals.count == 1 {
                    PiBodyText("This is your only goal, so it gets 100%.")
                } else {
                    PiTotalLine(total: setup.splitTotal)
                }
            }
        } dock: {
            Button("Lock this split", systemImage: PiIcon.lock, action: lock)
                .buttonStyle(.piPrimary)
                .disabled(!setup.isSplitComplete)
            PiCaption("Locked amounts never change.", alignment: .center)
        }
    }

    /// "₹60,000 · needs ₹19,583 a month"
    private func detail(for draft: GoalDraft) -> String {
        let amount = store.setup.amount(for: draft.id)
        let months = GoalMath.monthsRemaining(start: draft.start, end: draft.end, asOf: store.currentMonth)
        let needs = GoalMath.requiredMonthly(target: draft.target, saved: amount, monthsRemaining: months)
        return String(localized: "\(MoneyFormat.rupees(amount)) · needs \(MoneyFormat.rupees(needs)) a month")
    }

    private func percentBinding(for id: GoalDraft.ID) -> Binding<Decimal> {
        Binding(
            get: { store.setup.goals.first { $0.id == id }?.standingPercent ?? 0 },
            set: { newValue in
                if let index = store.setup.goals.firstIndex(where: { $0.id == id }) {
                    store.setup.goals[index].standingPercent = newValue
                }
            }
        )
    }

    private func lock() {
        do {
            try store.completeSetup()
            router.reset()
        } catch {
            store.showToast(userMessage(for: error))
        }
    }
}

#Preview {
    let store = LedgerStore.preview()
    store.setup.openingBalance = 100_000
    store.setup.goals = DemoProfile.goalDrafts(start: DemoScenario.start)
    return NavigationStack {
        Screen08OpeningSplitView()
    }
    .environment(store)
    .environment(Router())
}
