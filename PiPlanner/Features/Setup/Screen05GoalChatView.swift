import SwiftUI

/// 5 / 5a / 5b / 5c · Goal chat first, the form as a fallback.
struct Screen05GoalChatView: View {
    @Environment(Router.self) private var router
    @State private var model: GoalChatViewModel

    init(store: LedgerStore) {
        _model = State(initialValue: GoalChatViewModel(store: store))
    }

    var body: some View {
        content(model)
    }

    private func content(_ model: GoalChatViewModel) -> some View {
        @Bindable var model = model
        return PiScreen {
            PiNavBar(title: "Plan your goals", showsBack: false, trailing: .tag("Step 3 of 3", .step))
        } content: {
            PiLargeTitle("What are you planning for?")
            if model.thread.items.isEmpty && model.goals.isEmpty {
                PiBodyText(Text("Describe your goals in a sentence. \(MoneyFormat.rupees(model.openingBalance)) is ready to split."))
                    .padding(.horizontal, 6)
            }
            if !model.isGrokAvailable {
                PiWarningBanner(text: Text("Grok is unavailable. You can still do this by hand."))
            }
            ForEach(model.thread.items) { item in
                ChatItemView(item: item) { outcome in
                    proposal(for: outcome, itemID: item.id, model: model)
                }
            }
            if model.thread.isThinking {
                ChatTypingIndicator()
            }
            if !model.goals.isEmpty {
                goalsCard(model)
            }
        } dock: {
            if model.thread.items.isEmpty && model.goals.isEmpty && model.isGrokAvailable {
                PiFlowLayout {
                    PiSuggestionChip(text: GoalChatViewModel.suggestion) {
                        Task { await send(GoalChatViewModel.suggestion, model: model) }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            PiComposer(text: $model.composerText, placeholder: "Describe a goal", isEnabled: model.isGrokAvailable) {
                Task { await send(model.composerText, model: model) }
            }
            HStack(spacing: PiSpacing.s) {
                Button("Use a form") {
                    router.setupPath.append(.goalForm(GoalFormRequest(mode: .setup)))
                }
                .buttonStyle(.piSecondary)
                Button("Continue") {
                    router.setupPath.append(.openingSplit)
                }
                .buttonStyle(.piPrimary)
                .disabled(!model.canContinue)
            }
        }
        .chatScrollAnchor()
    }

    private func goalsCard(_ model: GoalChatViewModel) -> some View {
        PiCard {
            PiSectionHeader(Text("Your goals"))
            ForEach(model.goals) { draft in
                PiSplitRow(
                    name: draft.trimmedName,
                    detail: Text(verbatim: "\(MoneyFormat.rupees(model.amount(for: draft.id))) of \(MoneyFormat.rupees(model.openingBalance))"),
                    detailTone: .success,
                    trailing: model.goals.count == 1
                        ? .fixed(PercentFormat.percent(100))
                        : .percent(Binding(
                            get: { draft.standingPercent },
                            set: { model.setPercent($0, for: draft.id) }
                        )),
                    showsDivider: draft.id != model.goals.last?.id
                )
                .contentShape(Rectangle())
                .contextMenu {
                    Button("Edit", systemImage: PiIcon.edit) {
                        router.setupPath.append(.goalForm(GoalFormRequest(mode: .setup, draft: draft)))
                    }
                    Button("Remove", systemImage: PiIcon.delete, role: .destructive) {
                        model.remove(draft.id)
                    }
                }
                .onTapGesture {
                    router.setupPath.append(.goalForm(GoalFormRequest(mode: .setup, draft: draft)))
                }
            }
            if model.goals.count == 1 {
                PiBodyText("This is your only goal, so it gets 100%.")
            } else {
                PiTotalLine(total: model.splitTotal)
            }
        }
    }

    private func proposal(for outcome: GrokOutcome, itemID: ChatItem.ID, model: GoalChatViewModel) -> ProposalPresentation? {
        guard case let .goalDrafts(drafts) = outcome else { return nil }
        let wording = model.presentation(of: drafts)
        return ProposalPresentation(
            title: wording.title,
            lines: wording.lines,
            onEdit: {
                if let request = model.edit(drafts, itemID: itemID) {
                    router.setupPath.append(.goalForm(request))
                }
            },
            onConfirm: { model.accept(drafts, itemID: itemID) }
        )
    }

    private func send(_ text: String, model: GoalChatViewModel) async {
        if case let .openForm(request) = await model.send(text) {
            router.setupPath.append(.goalForm(request))
        }
    }
}

#Preview {
    let store = LedgerStore.preview()
    store.setup.openingBalance = 100_000
    return NavigationStack {
        Screen05GoalChatView(store: store)
    }
    .environment(store)
    .environment(Router())
}
