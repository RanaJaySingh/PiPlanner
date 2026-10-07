import Foundation
import Observation

/// Screen 19: questions answered from engine numbers; action sentences come back as proposal cards.
@MainActor
@Observable
final class AskViewModel {
    /// Where a confirmed or edited proposal leads. The view turns these into navigation.
    enum Destination: Equatable {
        case transfer(TransferRequest)
        case goalForm(GoalFormRequest)
        case entry(HistoryEntry.ID)
    }

    var composerText = ""
    private(set) var grokFailed = false
    private let store: LedgerStore

    nonisolated static let suggestions = ["What happens if I change the split?", "How are my goals doing?"]

    init(store: LedgerStore) {
        self.store = store
    }

    var thread: ChatThread { store.askThread }
    var isGrokAvailable: Bool { store.isGrokAvailable && !grokFailed }

    func send(_ text: String) async -> Destination? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !thread.isThinking else { return nil }
        composerText = ""

        store.askThread.items.append(ChatItem(content: .customer(trimmed)))
        let utterance = store.askThread.utterance(for: trimmed)
        store.askThread.isThinking = true
        let outcome = await store.askGrok(utterance, surface: .ask, followUpCount: thread.followUpCount)
        store.askThread.isThinking = false
        store.askThread.record(outcome, utterance: utterance)

        switch outcome {
        case .goalDrafts, .entryGoal, .transfer:
            store.askThread.items.append(ChatItem(content: .proposal(outcome)))
        case let .followUp(question):
            store.askThread.items.append(ChatItem(content: .grok(question)))
            store.askThread.items.append(ChatItem(content: .notice(String(localized: "Asked once more, then the Goal form opens."))))
        case let .answer(text), let .unsupported(text):
            store.askThread.items.append(ChatItem(content: .grok(text)))
        case .openForm:
            store.askThread.items.append(ChatItem(content: .grok(String(localized: "Let's fill in the details in a form."))))
            return .goalForm(GoalFormRequest(mode: .standalone))
        case .unavailable:
            grokFailed = true
        }
        return nil
    }

    // MARK: - Proposal cards

    func presentation(of outcome: GrokOutcome) -> (title: String, lines: [String])? {
        let ledger = store.ledger
        switch outcome {
        case let .transfer(proposal):
            let from = LedgerText.goalName(proposal.fromGoalID, in: ledger)
            let to = LedgerText.goalName(proposal.toGoalID, in: ledger)
            let fromAfter = ledger.saved(proposal.fromGoalID) - proposal.amount
            let toAfter = ledger.saved(proposal.toGoalID) + proposal.amount
            return (
                String(localized: "Move \(MoneyFormat.rupees(proposal.amount)) from \(from) to \(to)"),
                [String(localized: "\(from) keeps \(MoneyFormat.rupees(fromAfter)) · \(to) reaches \(MoneyFormat.rupees(toAfter))")]
            )
        case let .entryGoal(proposal):
            let draft = proposal.draft
            let amount = ledger.openEntry?.amount ?? 0
            let parts = proposal.split.allocate(amount).map { slice in
                let name = slice.goalID == draft.id ? draft.trimmedName : LedgerText.goalName(slice.goalID, in: ledger)
                return "\(name) \(MoneyFormat.rupees(slice.amount))"
            }
            return (
                String(localized: "New goal: \(draft.trimmedName)"),
                [
                    goalLine(draft),
                    String(localized: "This \(MoneyFormat.rupees(amount)): \(parts.joined(separator: " · "))"),
                ]
            )
        case let .goalDrafts(drafts):
            return (
                String(localized: "New goal: \(drafts.map(\.trimmedName).joined(separator: " · "))"),
                drafts.map(goalLine)
            )
        default:
            return nil
        }
    }

    /// "₹50,000 by Mar 2027"
    private func goalLine(_ draft: GoalDraft) -> String {
        String(localized: "\(MoneyFormat.rupees(draft.target)) by \(DateFormat.month(draft.end))")
    }

    /// Confirm never moves money by itself: it opens the matching screen, pre-filled.
    func confirm(_ outcome: GrokOutcome, itemID: ChatItem.ID) -> Destination? {
        store.askThread.resolve(itemID)
        switch outcome {
        case let .transfer(proposal):
            return .transfer(TransferRequest(fromGoalID: proposal.fromGoalID, toGoalID: proposal.toGoalID, amount: proposal.amount))
        case let .entryGoal(proposal):
            guard let entry = store.ledger.openEntry else { return nil }
            do {
                try store.createGoal(proposal.draft, placement: .onOpenEntry)
                store.proposedEntrySplit = proposal.split
                return .entry(entry.id)
            } catch {
                store.showToast(userMessage(for: error))
                return nil
            }
        case let .goalDrafts(drafts):
            return drafts.first.map { .goalForm(GoalFormRequest(mode: .standalone, draft: $0)) }
        default:
            return nil
        }
    }

    /// Edit opens the same screen without applying anything.
    func edit(_ outcome: GrokOutcome, itemID: ChatItem.ID) -> Destination? {
        store.askThread.resolve(itemID)
        switch outcome {
        case let .entryGoal(proposal):
            return .goalForm(GoalFormRequest(mode: .onEntry, draft: proposal.draft))
        default:
            return confirm(outcome, itemID: itemID)
        }
    }
}
