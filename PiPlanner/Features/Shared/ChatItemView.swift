import SwiftUI

/// Renders one `ChatItem`. Proposal cards get their wording and actions from the caller.
struct ChatItemView: View {
    let item: ChatItem
    let proposal: (GrokOutcome) -> ProposalPresentation?

    var body: some View {
        switch item.content {
        case let .customer(text):
            PiChatBubble(author: .customer, text: Text(verbatim: text))
        case let .grok(text):
            PiChatBubble(author: .grok, text: Text(verbatim: text))
        case let .notice(text):
            PiCaption(Text(verbatim: text))
                .padding(.horizontal, 6)
        case let .proposal(outcome):
            if let presentation = proposal(outcome) {
                PiProposalCard(
                    title: Text(verbatim: presentation.title),
                    lines: presentation.lines,
                    onEdit: item.isResolved ? nil : presentation.onEdit,
                    onConfirm: item.isResolved ? nil : presentation.onConfirm
                )
            }
        }
    }
}

/// Wording and actions for a Grok proposal card.
struct ProposalPresentation {
    let title: String
    let lines: [String]
    let onEdit: () -> Void
    let onConfirm: () -> Void
}

/// "Grok is thinking" placeholder bubble.
struct ChatTypingIndicator: View {
    var body: some View {
        PiChatBubble(author: .grok, text: Text(verbatim: "…"))
            .accessibilityLabel("Grok is thinking")
    }
}
