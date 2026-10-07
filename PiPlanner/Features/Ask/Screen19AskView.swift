import SwiftUI

/// 19 / 19a–19d / 13f / 16c · Ask tab.
struct Screen19AskView: View {
    @Environment(Router.self) private var router
    @State private var model: AskViewModel

    init(store: LedgerStore) {
        _model = State(initialValue: AskViewModel(store: store))
    }

    var body: some View {
        content(model)
    }

    private func content(_ model: AskViewModel) -> some View {
        @Bindable var model = model
        return PiScreen {
            PiLargeTitle("Ask")
            if !model.isGrokAvailable {
                PiWarningBanner(text: Text("Grok is unavailable. You can still do this by hand."))
            } else if model.thread.items.isEmpty {
                PiCard {
                    PiBodyText("Ask about your plan, or tell Grok what to do. Changes come back as a card to confirm.")
                }
            }
            ForEach(model.thread.items) { item in
                ChatItemView(item: item) { outcome in
                    presentation(for: outcome, itemID: item.id, model: model)
                }
            }
            if model.thread.isThinking {
                ChatTypingIndicator()
            }
        } dock: {
            if model.thread.items.isEmpty && model.isGrokAvailable {
                PiFlowLayout {
                    ForEach(AskViewModel.suggestions, id: \.self) { suggestion in
                        PiSuggestionChip(text: suggestion) {
                            Task { await send(suggestion, model: model) }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            PiComposer(text: $model.composerText, placeholder: "Ask Grok", isEnabled: model.isGrokAvailable) {
                Task { await send(model.composerText, model: model) }
            }
        }
        .chatScrollAnchor()
    }

    private func presentation(for outcome: GrokOutcome, itemID: ChatItem.ID, model: AskViewModel) -> ProposalPresentation? {
        guard let wording = model.presentation(of: outcome) else { return nil }
        return ProposalPresentation(
            title: wording.title,
            lines: wording.lines,
            onEdit: { open(model.edit(outcome, itemID: itemID)) },
            onConfirm: { open(model.confirm(outcome, itemID: itemID)) }
        )
    }

    private func send(_ text: String, model: AskViewModel) async {
        open(await model.send(text))
    }

    private func open(_ destination: AskViewModel.Destination?) {
        switch destination {
        case let .transfer(request):
            router.push(.transfer(request))
        case let .goalForm(request):
            router.push(.goalForm(request))
        case let .entry(entryID):
            returnToEntry(entryID)
        case nil:
            break
        }
    }

    /// Back to the entry the customer came from if it is still on a stack, otherwise open it here.
    private func returnToEntry(_ entryID: HistoryEntry.ID) {
        if let tab = MainTab.allCases.first(where: { router.path(for: $0).last == .entry(entryID) }) {
            router.selectedTab = tab
        } else {
            router.push(.entry(entryID))
        }
    }
}

#Preview("19") {
    let store = LedgerStore.preview(stage: .afterCustomCredit)
    return NavigationStack {
        Screen19AskView(store: store)
    }
    .environment(store)
    .environment(Router())
}
