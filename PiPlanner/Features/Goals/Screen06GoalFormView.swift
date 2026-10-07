import SwiftUI

/// 6 / 6c / 6e / 6n / 13g · Goal form.
struct Screen06GoalFormView: View {
    @Environment(LedgerStore.self) private var store
    @Environment(Router.self) private var router
    @Environment(\.dismiss) private var dismiss
    @State private var model: GoalFormViewModel
    @State private var picker: DateField?

    private enum DateField: Identifiable {
        case start, end
        var id: Self { self }
    }

    init(store: LedgerStore, request: GoalFormRequest) {
        _model = State(initialValue: GoalFormViewModel(store: store, request: request))
    }

    var body: some View {
        @Bindable var model = model
        PiScreen {
            PiNavBar(title: model.isEditing ? "Edit goal" : "New goal")
        } content: {
            fieldsCard(model)
            shareCard(model)
            summaryCard(model)
        } dock: {
            Button("Save", action: save)
                .buttonStyle(.piPrimary)
                .disabled(!model.canSave)
        }
        .sheet(item: $picker) { field in
            switch field {
            case .start:
                PiMonthPickerSheet(title: Text("Start"), selection: $model.draft.start, range: model.startRange)
            case .end:
                PiMonthPickerSheet(title: Text("End"), selection: $model.draft.end, range: model.endRange)
            }
        }
    }

    private func fieldsCard(_ model: GoalFormViewModel) -> some View {
        @Bindable var model = model
        return PiCard(style: .form) {
            PiFormRow(label: Text("Name")) {
                TextField("Goal name", text: $model.draft.name)
                    .accessibilityLabel("Goal name")
                    .textInputAutocapitalization(.words)
                    .submitLabel(.done)
            }
            PiFormRow(label: Text("Target")) {
                PiInlineAmountField(amount: $model.draft.target, accessibilityLabel: Text("Target"))
            }
            PiFormRow(label: Text("Start")) {
                Button(DateFormat.month(model.draft.start)) { picker = .start }
                    .buttonStyle(.plain)
                    .accessibilityHint("Choose the start month")
            }
            PiFormRow(label: Text("End"), showsDivider: false) {
                Button(DateFormat.month(model.draft.end)) { picker = .end }
                    .buttonStyle(.plain)
                    .accessibilityHint("Choose the end month")
            }
            if let issue = model.issueMessage {
                PiErrorLine(text: Text(verbatim: issue))
                    .padding(.bottom, PiSpacing.s)
            }
        }
    }

    @ViewBuilder
    private func shareCard(_ model: GoalFormViewModel) -> some View {
        @Bindable var model = model
        switch model.shareSection {
        case .hidden:
            EmptyView()
        case .onlyGoal:
            PiCard {
                PiValueRow(label: Text("Share of new credits"), value: Text(verbatim: PercentFormat.percent(100)), showsDivider: false)
                PiBodyText("Only goal, so it gets 100%.")
                if model.isEditing { pendingWarning }
            }
        case .editable:
            PiCard {
                PiFormRow(label: Text("Share of new credits"), showsDivider: false) {
                    PiPercentField(value: $model.draft.standingPercent, accessibilityLabel: Text("Share of new credits"))
                }
                if model.isEditing {
                    pendingWarning
                } else {
                    PiBodyText(Text(verbatim: model.shareExample))
                }
            }
        }
    }

    private var pendingWarning: some View {
        PiWarningBanner(text: Text("Changes apply at the next credit. Earlier history stays as it is."))
    }

    private func summaryCard(_ model: GoalFormViewModel) -> some View {
        PiCard(style: .form) {
            if model.showsSavedSoFar {
                PiValueRow(
                    label: Text("Saved so far"),
                    value: Text("\(MoneyFormat.rupees(model.savedSoFar)) · locked"),
                    tone: .locked
                )
            }
            PiValueRow(
                label: Text("Needs a month"),
                value: Text(verbatim: MoneyFormat.rupees(model.requiredMonthly)),
                showsDivider: false
            )
        }
    }

    private func save() {
        do {
            let result = try model.save()
            dismiss()
            if result == .savedNeedsStandingSplit {
                router.mainSheet = .standingSplit
            }
        } catch {
            store.showToast(userMessage(for: error))
        }
    }
}

#Preview("6 · setup") {
    let store = LedgerStore.preview()
    return NavigationStack {
        Screen06GoalFormView(store: store, request: GoalFormRequest(mode: .setup, draft: DemoProfile.goalDrafts(start: DemoScenario.start)[0]))
    }
    .environment(store)
    .environment(Router())
}

#Preview("6e · edit") {
    let store = LedgerStore.preview(stage: .afterCustomCredit)
    let car = store.ledger.activeGoals[0]
    return NavigationStack {
        Screen06GoalFormView(store: store, request: GoalFormRequest(mode: .edit(car.id)))
    }
    .environment(store)
    .environment(Router())
}
