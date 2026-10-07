import Foundation

/// One line in a Grok conversation: a bubble, a proposal card, or a notice.
struct ChatItem: Identifiable, Hashable {
    enum Content: Hashable {
        case customer(String)
        case grok(String)
        case proposal(GrokOutcome)
        /// Small grey caption, e.g. "Asked once more, then the Goal form opens."
        case notice(String)
    }

    let id = UUID()
    var content: Content
    /// Proposal cards lose their buttons once confirmed or edited.
    var isResolved = false
}

/// A Grok conversation and its follow-up state.
struct ChatThread: Hashable {
    var items: [ChatItem] = []
    var followUpCount = 0
    /// Earlier sentences joined to the next one while a follow-up is pending.
    var pendingUtterance: String?
    var isThinking = false

    /// The text sent to Grok: earlier unanswered sentences plus the new one.
    func utterance(for text: String) -> String {
        [pendingUtterance, text].compactMap { $0 }.joined(separator: ". ")
    }

    mutating func record(_ outcome: GrokOutcome, utterance: String) {
        switch outcome {
        case .followUp:
            followUpCount += 1
            pendingUtterance = utterance
        default:
            followUpCount = 0
            pendingUtterance = nil
        }
    }

    mutating func resolve(_ itemID: ChatItem.ID) {
        guard let index = items.firstIndex(where: { $0.id == itemID }) else { return }
        items[index].isResolved = true
    }
}
