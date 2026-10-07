import SwiftUI

/// 13 / 13a–13g / 13t / 12a · A History entry. Open entries take one split change, then Save and lock.
struct Screen13EntryView: View {
    @Environment(LedgerStore.self) private var store
    @Environment(Router.self) private var router
    @State private var model: EntryViewModel
    @State private var goalPicker: GoalPickerPurpose?

    private enum GoalPickerPurpose: Identifiable {
        case edit, delete
        var id: Self { self }
    }

    init(store: LedgerStore, entryID: HistoryEntry.ID) {
        _model = State(initialValue: EntryViewModel(store: store, entryID: entryID))
    }

    var body: some View {
        Group {
            if let entry = model.entry {
                if entry.isOpen {
                    openEntry(entry)
                } else {
                    SavedEntryView(entry: entry, model: model)
                }
            } else {
                PiScreen { PiNavBar(title: "History") } content: {
                    PiBodyText("This entry no longer exists.")
                }
            }
        }
        .animation(.snappy, value: model.entry?.state)
        .onAppear(perform: model.applyProposedSplit)
        .onChange(of: store.proposedEntrySplit) { model.applyProposedSplit() }
        .onChange(of: store.ledger.activeGoalIDs) { model.goalsChanged() }
        .confirmationDialog(goalPickerTitle, isPresented: Binding(
            get: { goalPicker != nil },
            set: { if !$0 { goalPicker = nil } }
        ), titleVisibility: .visible) {
            ForEach(model.activeGoals) { goal in
                Button(goal.name) { pick(goal) }
            }
        }
    }

    // MARK: - Open entry

    private func openEntry(_ entry: HistoryEntry) -> some View {
        PiScreen {
            PiNavBar(
                title: "New credit",
                trailing: entry.source == .typed ? .tag("Typed", .neutral) : .tag("Assign now", .assign)
            )
        } content: {
            if model.isEditing {
                PiCard {
                    PiAmountHeadline(label: Text("New amount"), amount: MoneyFormat.rupees(entry.amount), tone: .success)
                }
                editCard(entry)
                if let explanation = model.explanation {
                    PiGrokNote(text: Text(verbatim: explanation))
                }
            } else {
                EntryBalanceCard(entry: entry)
                PiLockedBlock(
                    title: Text("Already saved, not changing"),
                    rows: model.lockedRows.map { .init(name: $0.name, amount: MoneyFormat.rupees($0.amount)) }
                )
                suggestionCard(entry)
            }
        } dock: {
            Button("Save and lock", systemImage: PiIcon.lock, action: save)
                .buttonStyle(.piPrimary)
                .disabled(!model.canSave)
            if !model.isEditing {
                if !model.hasSingleGoal {
                    PiCaption("You can change this split once.", alignment: .center)
                }
                goalLinks
            }
        }
    }

    private func suggestionCard(_ entry: HistoryEntry) -> some View {
        PiCard(spacing: 0) {
            PiSectionHeader(Text("Split \(MoneyFormat.rupees(entry.amount))"), trailing: Text("This credit only"))
                .padding(.bottom, PiSpacing.xs)
            ForEach(model.suggestedRows, id: \.goalID) { row in
                PiValueRow(
                    label: Text(verbatim: row.name),
                    value: Text(verbatim: "\(PercentFormat.percent(row.percent)) · \(MoneyFormat.rupees(row.amount))"),
                    showsDivider: row.goalID != model.suggestedRows.last?.goalID
                )
            }
            if model.hasSingleGoal {
                PiBodyText("This is your only goal, so it gets 100%.")
                    .padding(.top, PiSpacing.s)
                createGoalLink
            } else {
                Button("Update percentages for this amount") {
                    withAnimation(.snappy) { model.beginEditing() }
                }
                .buttonStyle(.piLink)
                .padding(.top, PiSpacing.s)
            }
        }
    }

    private func editCard(_ entry: HistoryEntry) -> some View {
        @Bindable var model = model
        let shortfalls = model.draftShortfalls
        return PiCard(spacing: 0) {
            PiSectionHeader(Text("Split \(MoneyFormat.rupees(entry.amount))"), trailing: Text("This credit only"))
            ForEach(model.draft.shares) { share in
                PiSplitRow(
                    name: LedgerText.goalName(share.goalID, in: model.ledger),
                    detail: Text(verbatim: editDetail(goalID: share.goalID, shortfall: shortfalls[share.goalID])),
                    detailTone: .success,
                    trailing: .percent(Binding(
                        get: { model.draft[share.goalID] },
                        set: { model.draft[share.goalID] = $0 }
                    ))
                )
            }
            createGoalLink
            PiTotalLine(total: model.draftTotal)
                .padding(.bottom, PiSpacing.m)
            PiToggleRow(title: Text("Use this split from the next credit too"), isOn: $model.carryForward)
        }
    }

    /// "₹15,000 · ₹4,583 behind this month"
    private func editDetail(goalID: UUID, shortfall: Decimal?) -> String {
        let amount = MoneyFormat.rupees(model.draftAmount(for: goalID))
        guard let shortfall else { return amount }
        return String(localized: "\(amount) · \(MoneyFormat.rupees(shortfall)) behind this month")
    }

    private var createGoalLink: some View {
        Button("+ Create a goal") {
            router.push(.goalForm(GoalFormRequest(mode: .onEntry)))
        }
        .buttonStyle(.piLink)
        .padding(.vertical, PiSpacing.s)
    }

    private var goalLinks: some View {
        HStack(spacing: PiSpacing.m) {
            Button("Create a goal") { router.push(.goalForm(GoalFormRequest(mode: .onEntry))) }
            Text(verbatim: "·").foregroundStyle(PiColor.inkPlaceholder).accessibilityHidden(true)
            Button("Edit a goal") { goalPicker = .edit }
            Text(verbatim: "·").foregroundStyle(PiColor.inkPlaceholder).accessibilityHidden(true)
            Button("Delete a goal") { goalPicker = .delete }
        }
        .buttonStyle(.piLink)
        .frame(maxWidth: .infinity)
    }

    private var goalPickerTitle: Text {
        goalPicker == .delete ? Text("Delete which goal?") : Text("Edit which goal?")
    }

    private func pick(_ goal: Goal) {
        switch goalPicker {
        case .edit: router.push(.goalForm(GoalFormRequest(mode: .edit(goal.id))))
        case .delete: router.push(.deleteGoal(goal.id))
        case nil: break
        }
        goalPicker = nil
    }

    private func save() {
        do {
            try withAnimation(.snappy) { try model.save() }
            UIAccessibility.post(notification: .announcement, argument: String(localized: "Saved and locked"))
        } catch {
            store.showToast(userMessage(for: error))
        }
    }
}

/// Previous balance, balance now (not for typed amounts), and the new amount.
private struct EntryBalanceCard: View {
    let entry: HistoryEntry

    var body: some View {
        PiCard(spacing: 0) {
            PiValueRow(label: Text("Previous balance"), value: Text(verbatim: MoneyFormat.rupees(entry.previousBalance)))
            if entry.source != .typed {
                PiValueRow(label: Text("Balance now"), value: Text(verbatim: MoneyFormat.rupees(entry.newBalance)))
            }
            PiAmountHeadline(label: Text("New amount"), amount: MoneyFormat.rupees(entry.amount), tone: .success)
        }
    }
}

/// 13a / 13d / 12a and the saved transfer, deletion and withdrawal entries. Original amounts never change.
private struct SavedEntryView: View {
    let entry: HistoryEntry
    let model: EntryViewModel

    var body: some View {
        PiScreen {
            PiNavBar(title: "\(LedgerText.historyTitle(entry, in: model.ledger).components(separatedBy: " · ").first ?? "")")
        } content: {
            headerCard
            if !model.savedRows.isEmpty {
                PiCard(spacing: 0) {
                    PiSectionHeader(entry.kind == .opening ? Text("Assigned") : Text("Split"))
                    ForEach(model.savedRows, id: \.goalID) { row in
                        PiSplitRow(
                            name: row.name,
                            detail: Text(verbatim: row.detail),
                            trailing: .fixed(MoneyFormat.rupees(row.amount), isLocked: true),
                            showsDivider: row.goalID != model.savedRows.last?.goalID
                        )
                    }
                }
            }
            if entry.kind == .opening {
                PiCaption("Original amounts never change.", alignment: .center)
            } else if entry.customSplit {
                PiCaption("A second change is not offered.", alignment: .center)
            }
        }
    }

    @ViewBuilder
    private var headerCard: some View {
        switch entry.kind {
        case .opening:
            PiCard {
                PiBalanceText(amount: MoneyFormat.rupees(entry.amount), alignment: .center)
                lockTag.frame(maxWidth: .infinity)
            }
        case .credit:
            PiCard(spacing: 0) {
                PiValueRow(label: Text("Previous balance"), value: Text(verbatim: MoneyFormat.rupees(entry.previousBalance)))
                if entry.source != .typed {
                    PiValueRow(label: Text("Balance now"), value: Text(verbatim: MoneyFormat.rupees(entry.newBalance)))
                }
                PiAmountHeadline(label: Text("New amount"), amount: MoneyFormat.rupees(entry.amount), tone: .success)
                lockTag.padding(.top, PiSpacing.m)
            }
        case .transfer:
            PiCard {
                PiStatement(Text(verbatim: LedgerText.historyDetail(entry, in: model.ledger)))
                PiBodyText("Moved between goals. The standing split did not change.")
                lockTag
            }
        case .goalDeleted:
            PiCard {
                PiStatement(Text("\(MoneyFormat.rupees(entry.amount)) released"))
                PiBodyText("The goal was removed and its saving moved to the goals below.")
                lockTag
            }
        case .withdrawal:
            PiCard(spacing: 0) {
                PiValueRow(label: Text("Previous balance"), value: Text(verbatim: MoneyFormat.rupees(entry.previousBalance)))
                PiValueRow(label: Text("Balance now"), value: Text(verbatim: MoneyFormat.rupees(entry.newBalance)))
                PiAmountHeadline(label: Text("Went down by"), amount: MoneyFormat.signedRupees(-entry.amount), tone: .warning)
                lockTag.padding(.top, PiSpacing.m)
            }
        }
    }

    private var lockTag: some View {
        PiLockTag(text: entry.customSplit ? Text("Saved and locked · Custom split") : Text("Saved and locked"))
    }
}

#Preview("13 · open") {
    let store = LedgerStore.preview(stage: .openCredit)
    return NavigationStack {
        Screen13EntryView(store: store, entryID: store.ledger.openEntry!.id)
    }
    .environment(store)
    .environment(Router())
}

#Preview("13d · saved custom") {
    let store = LedgerStore.preview(stage: .afterCustomCredit)
    return NavigationStack {
        Screen13EntryView(store: store, entryID: store.ledger.history[1].id)
    }
    .environment(store)
    .environment(Router())
}

#Preview("12a · opening") {
    let store = LedgerStore.preview(stage: .afterOpening)
    return NavigationStack {
        Screen13EntryView(store: store, entryID: store.ledger.history[0].id)
    }
    .environment(store)
    .environment(Router())
}
