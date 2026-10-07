import SwiftUI

/// 9 / 9b / 9c / 10a / 11 / 20a · Goals tab.
struct Screen09GoalsView: View {
    @Environment(LedgerStore.self) private var store
    @Environment(Router.self) private var router
    @State private var isReading = false

    var body: some View {
        let ledger = store.ledger
        PiScreen {
            PiAppHeader(initial: String(DemoProfile.customerName.prefix(1)))
            hero(ledger)
            if let open = ledger.openEntry {
                PiAssignBanner(message: Text("\(MoneyFormat.rupees(open.amount)) to assign")) {
                    router.push(.entry(open.id))
                }
            }
            goalsCard(ledger)
        }
    }

    // MARK: - Hero

    private func hero(_ ledger: Ledger) -> some View {
        PiCard(style: .hero, spacing: 6) {
            PiGreetingRow(
                greeting: Text(verbatim: LedgerText.greeting(name: DemoProfile.customerName, now: store.now, calendar: store.calendar)),
                onInsights: { router.selectedTab = .history },
                onSettings: { router.push(.settings) }
            )
            .padding(.bottom, PiSpacing.s)
            PiBodyText(Text(verbatim: String(localized: "Dedicated savings · \(store.dedicatedAccount?.shortLabel ?? "")")))
            PiBalanceText(amount: MoneyFormat.rupees(ledger.snapshot ?? 0))
            PiBodyText(Text(verbatim: LedgerText.lastUpdate(store.lastBalanceUpdate, isAutomatic: store.isAutomatic, now: store.now, calendar: store.calendar)))
            HStack(alignment: .top, spacing: 6) {
                if store.isAutomatic {
                    PiQuickTile(icon: PiIcon.sync, title: Text("Sync")) {
                        Task { await sync() }
                    }
                    .disabled(ledger.openEntry != nil || isReading)
                } else {
                    PiQuickTile(icon: PiIcon.sync, title: Text("Update balance")) {
                        router.mainSheet = .updateBalance(nil)
                    }
                    .disabled(ledger.openEntry != nil)
                }
                PiQuickTile(icon: PiIcon.add, title: Text("New goal")) {
                    router.push(.goalForm(GoalFormRequest(mode: .standalone)))
                }
                PiQuickTile(icon: PiIcon.transfer, title: Text("Transfer")) {
                    router.push(.transfer(TransferRequest()))
                }
                .disabled(ledger.activeGoals.count < 2 || ledger.assignedTotal <= 0)
                PiQuickTile(icon: PiIcon.history, title: Text("History")) {
                    router.selectedTab = .history
                }
            }
            .padding(.top, 14)
        }
    }

    // MARK: - Goals

    private func goalsCard(_ ledger: Ledger) -> some View {
        PiCard(spacing: 0) {
            PiSectionHeader(Text("Your Goals"))
            ForEach(ledger.activeGoals) { goal in
                Button {
                    router.push(.goalDetail(goal.id))
                } label: {
                    goalCard(goal)
                }
                .buttonStyle(.plain)
                .accessibilityHint("Opens goal details")
            }
            Button("+ New goal") {
                router.push(.goalForm(GoalFormRequest(mode: .standalone)))
            }
            .buttonStyle(.piLink)
            .padding(.top, PiSpacing.s)
        }
    }

    private func goalCard(_ goal: Goal) -> some View {
        let progress = store.progress(of: goal.id)
        return PiGoalCard(
            name: goal.name,
            progressText: "\(MoneyFormat.rupees(progress?.saved ?? 0)) of \(MoneyFormat.rupees(goal.target))",
            fraction: progress?.fractionComplete ?? 0,
            status: LedgerText.statusKind(progress?.status ?? .onTrack),
            needsText: Text("Needs \(MoneyFormat.rupees(progress?.requiredMonthly ?? 0)) a month"),
            shareText: Text("\(PercentFormat.percent(goal.standingPercent)) of credits"),
            hasPendingEdit: goal.pendingEdit != nil
        )
    }

    // MARK: - Sync

    private func sync() async {
        isReading = true
        defer { isReading = false }
        do {
            switch try await store.syncBalance() {
            case .unchanged:
                store.showToast(String(localized: "No new credit since the last sync."))
            case let .changed(preview):
                router.mainSheet = .sync(preview)
            }
        } catch {
            store.showToast(userMessage(for: error))
        }
    }
}

#Preview("9") {
    NavigationStack {
        Screen09GoalsView()
    }
    .environment(LedgerStore.preview(stage: .afterOpening))
    .environment(Router())
}

#Preview("9b · entry open") {
    NavigationStack {
        Screen09GoalsView()
    }
    .environment(LedgerStore.preview(stage: .openCredit))
    .environment(Router())
}
