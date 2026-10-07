import Foundation
import Observation

/// Screen 5: turns sentences into goal drafts through Grok and keeps the opening split.
@MainActor
@Observable
final class GoalChatViewModel {
    enum Action: Equatable {
        case none
        case openForm(GoalFormRequest)
    }

    private let store: LedgerStore
    var composerText = ""
    /// Set when a live call fails, so the screen falls back to forms (5c).
    private(set) var grokFailed = false

    init(store: LedgerStore) {
        self.store = store
    }

    var thread: ChatThread { store.setup.chat }
    var goals: [GoalDraft] { store.setup.goals }
    var openingBalance: Decimal { store.setup.openingBalance }
    var isGrokAvailable: Bool { store.isGrokAvailable && !grokFailed }
    var canContinue: Bool { store.setup.isSplitComplete }
    var splitTotal: Decimal { store.setup.splitTotal }

    nonisolated static let suggestion = "A ₹10 lakh car by Sep 2030 and a ₹2 lakh emergency fund in a year"

    func amount(for draftID: GoalDraft.ID) -> Decimal {
        store.setup.amount(for: draftID)
    }

    func setPercent(_ percent: Decimal, for draftID: GoalDraft.ID) {
        guard let index = store.setup.goals.firstIndex(where: { $0.id == draftID }) else { return }
        store.setup.goals[index].standingPercent = percent
    }

    func remove(_ draftID: GoalDraft.ID) {
        store.setup.goals.removeAll { $0.id == draftID }
        if store.setup.goals.count == 1 {
            store.setup.goals[0].standingPercent = 100
        }
    }

    // MARK: - Grok

    func send(_ text: String) async -> Action {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !thread.isThinking else { return .none }
        composerText = ""

        store.setup.chat.items.append(ChatItem(content: .customer(trimmed)))
        let utterance = store.setup.chat.utterance(for: trimmed)
        store.setup.chat.isThinking = true
        let outcome = await store.askGrok(utterance, surface: .goalSetup, followUpCount: thread.followUpCount)
        store.setup.chat.isThinking = false
        store.setup.chat.record(outcome, utterance: utterance)

        switch outcome {
        case .goalDrafts:
            store.setup.chat.items.append(ChatItem(content: .proposal(outcome)))
        case let .followUp(question):
            store.setup.chat.items.append(ChatItem(content: .grok(question)))
        case let .answer(text), let .unsupported(text):
            store.setup.chat.items.append(ChatItem(content: .grok(text)))
        case .openForm:
            store.setup.chat.items.append(ChatItem(content: .grok(String(localized: "Let's fill in the details in a form."))))
            return .openForm(GoalFormRequest(mode: .setup))
        case .unavailable:
            grokFailed = true
        case .entryGoal, .transfer:
            store.setup.chat.items.append(ChatItem(content: .grok(String(localized: "Describe a goal with a target amount and a date."))))
        }
        return .none
    }

    /// Wording for a drafts card, e.g. "Split of ₹1,00,000: Car 60% ₹60,000 · Emergency 40% ₹40,000".
    func presentation(of drafts: [GoalDraft]) -> (title: String, lines: [String]) {
        let title = drafts.map(\.trimmedName).joined(separator: " · ")
        var lines = drafts.map { draft in
            String(localized: "\(draft.trimmedName): \(MoneyFormat.rupees(draft.target)) by \(DateFormat.month(draft.end))")
        }
        let split = Split(drafts.map { Split.Share(goalID: $0.id, percent: $0.standingPercent) })
        let parts = drafts.map { draft in
            "\(draft.trimmedName) \(PercentFormat.percent(draft.standingPercent)) \(MoneyFormat.rupees(split.amount(for: draft.id, of: openingBalance)))"
        }
        lines.append(String(localized: "Split of \(MoneyFormat.rupees(openingBalance)): \(parts.joined(separator: " · "))"))
        return (title, lines)
    }

    /// Adds the drafts. With goals already present, the split is suggested again across all of them.
    func accept(_ drafts: [GoalDraft], itemID: ChatItem.ID) {
        let existing = store.setup.goals.filter { current in !drafts.contains { $0.id == current.id } }
        let combined = existing.isEmpty
            ? drafts
            : GrokOrchestrator.suggestedSplit(for: existing + drafts, asOf: store.currentMonth)
        store.setup.goals = combined
        store.setup.chat.resolve(itemID)
    }

    /// Edit accepts the drafts and opens the first one in the form.
    func edit(_ drafts: [GoalDraft], itemID: ChatItem.ID) -> GoalFormRequest? {
        accept(drafts, itemID: itemID)
        guard let first = drafts.first, let saved = store.setup.goals.first(where: { $0.id == first.id }) else { return nil }
        return GoalFormRequest(mode: .setup, draft: saved)
    }
}
