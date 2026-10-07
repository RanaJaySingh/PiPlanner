import SwiftUI

/// 14 · Goal detail: progress, plan, and the History slices for this goal.
struct Screen14GoalDetailView: View {
    let goalID: Goal.ID

    @Environment(LedgerStore.self) private var store
    @Environment(Router.self) private var router

    var body: some View {
        if let goal = store.ledger.goal(goalID), !goal.isDeleted, let progress = store.progress(of: goalID) {
            content(goal: goal, progress: progress)
        } else {
            PiScreen { PiNavBar(title: "Goal") } content: {
                PiBodyText("This goal was deleted. Its History entries are kept.")
            }
        }
    }

    private func content(goal: Goal, progress: GoalProgress) -> some View {
        PiScreen {
            PiNavBar(title: "\(goal.name)", trailing: .icon(systemName: PiIcon.edit, accessibilityLabel: "Edit goal") {
                router.push(.goalForm(GoalFormRequest(mode: .edit(goal.id))))
            })
        } content: {
            PiCard {
                PiChoiceRow(
                    icon: PiIcon.goal(named: goal.name),
                    title: Text(verbatim: savedHeadline(progress)),
                    subtitle: Text("Saved so far"),
                    titleIsAmount: true
                )
                PiProgressBar(fraction: progress.fractionComplete)
                PiCaption(Text("of \(MoneyFormat.rupees(progress.target)) target · \(reachedPercent(progress)) reached"))
            }
            if goal.pendingEdit != nil {
                PiPendingNote()
            }
            PiCard(style: .form) {
                PiValueRow(label: Text("Needs a month"), value: Text(verbatim: MoneyFormat.rupees(progress.requiredMonthly)))
                PiValueRow(label: Text("Dates"), value: Text(verbatim: DateFormat.range(from: goal.start, to: goal.end)))
                PiValueRow(label: Text("Share of new credits"), value: Text(verbatim: shareText(goal)), showsDivider: false)
            }
            historyCard
        } dock: {
            HStack(spacing: PiSpacing.s) {
                Button("Transfer") {
                    router.push(.transfer(TransferRequest(fromGoalID: goal.id)))
                }
                .buttonStyle(.piSecondary)
                .disabled(store.ledger.activeGoals.count < 2)
                Button("Edit goal") {
                    router.push(.goalForm(GoalFormRequest(mode: .edit(goal.id))))
                }
                .buttonStyle(.piPrimary)
            }
            Button("Delete goal") {
                router.push(.deleteGoal(goal.id))
            }
            .buttonStyle(.piLink(.danger))
        }
    }

    @ViewBuilder
    private var historyCard: some View {
        let slices = store.ledger.slices(for: goalID)
        if !slices.isEmpty {
            PiCard(spacing: 0) {
                PiSectionHeader(Text("From History"))
                ForEach(slices, id: \.entry.id) { item in
                    Button {
                        router.push(.entry(item.entry.id))
                    } label: {
                        PiHistoryRow(
                            icon: LedgerText.historyIcon(item.entry),
                            title: Text(verbatim: LedgerText.historyTitle(item.entry, in: store.ledger)),
                            detail: MoneyFormat.signedRupees(item.amount),
                            dateText: DateFormat.day(item.entry.date, relativeTo: store.now, calendar: store.calendar),
                            isOpen: false,
                            showsDivider: item.entry.id != slices.last?.entry.id
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    /// "₹75,000 · Behind ₹4,583"
    private func savedHeadline(_ progress: GoalProgress) -> String {
        let saved = MoneyFormat.rupees(progress.saved)
        switch progress.status {
        case .onTrack: return saved
        case let .behind(amount): return String(localized: "\(saved) · Behind \(MoneyFormat.rupees(amount))")
        case .ended: return String(localized: "\(saved) · Ended")
        }
    }

    private func reachedPercent(_ progress: GoalProgress) -> String {
        let whole = Decimal(Int(progress.fractionComplete * 100))
        return PercentFormat.percent(whole)
    }

    /// "50% · ₹25,000 per ₹50,000"
    private func shareText(_ goal: Goal) -> String {
        let reference = store.referenceCreditAmount
        let part = (reference * goal.standingPercent / 100).rounded()
        return String(localized: "\(PercentFormat.percent(goal.standingPercent)) · \(MoneyFormat.rupees(part)) per \(MoneyFormat.rupees(reference))")
    }
}

#Preview {
    let store = LedgerStore.preview(stage: .afterCustomCredit)
    return NavigationStack {
        Screen14GoalDetailView(goalID: store.ledger.activeGoals[0].id)
    }
    .environment(store)
    .environment(Router())
}
