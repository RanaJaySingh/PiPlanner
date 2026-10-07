import Foundation

/// Offline Grok for the demo. Produces the same JSON contract as the live client from the
/// context it is given, so every reply goes through the same validation.
struct MockGrokClient: GrokClient {
    func reply(to request: GrokRequest) async throws -> GrokReply {
        let today = YearMonth(isoString: request.context.today) ?? YearMonth(year: 2026, month: 10)
        let parser = UtteranceParser(today: today)
        let text = request.utterance
        let goalNames = request.context.goals.map(\.name)

        if let endpoints = parser.transferEndpoints(in: text),
           let from = parser.goalNamed(endpoints.from, among: goalNames),
           let to = parser.goalNamed(endpoints.to, among: goalNames),
           let amount = parser.amounts(in: text).first {
            return GrokReply(kind: .transfer, transfer: .init(from: from, to: to, amount: amount))
        }

        if parser.asksToMoveMoneyOut(text) {
            return GrokReply(kind: .unsupported, message: "PiPlanner only plans your dedicated savings. It never moves money.")
        }

        if parser.isQuestion(text) {
            return GrokReply(kind: .answer, message: answer(to: text, context: request.context))
        }

        let drafts = parser.clauses(of: text).compactMap { clause -> (name: String, amount: Decimal?, end: YearMonth?)? in
            guard let name = parser.goalName(in: clause) else { return nil }
            return (name, parser.amounts(in: clause).first, parser.endMonth(in: clause))
        }

        guard !drafts.isEmpty else {
            return GrokReply(kind: .followUp, message: followUp(noun: nil, request: request))
        }
        if let incomplete = drafts.first(where: { $0.amount == nil || $0.end == nil }) {
            return GrokReply(kind: .followUp, message: followUp(noun: incomplete.name, request: request))
        }

        let goals = drafts.compactMap { draft -> GrokReply.GoalPayload? in
            guard let amount = draft.amount, let end = draft.end else { return nil }
            return GrokReply.GoalPayload(name: draft.name, target: amount, end: end.isoString, start: today.isoString)
        }

        if request.surface == .ask, request.context.openEntryAmount != nil, let goal = goals.first, goals.count == 1 {
            let newShare = parser.percent(in: text) ?? 20
            return GrokReply(kind: .entryGoal, goals: [goal], entrySplit: entrySplit(adding: goal.name, share: newShare, context: request.context))
        }
        return GrokReply(kind: .goals, goals: goals)
    }

    /// The new goal takes `share`; existing goals scale down from their standing split, in steps of 5%.
    private func entrySplit(adding name: String, share: Decimal, context: GrokContext) -> [GrokReply.SharePayload] {
        let existing = context.goals
        let parts = Apportion.largestRemainder(total: 100 - share, weights: existing.map(\.standingPercent), unit: 5)
        return zip(existing, parts).map { GrokReply.SharePayload(goal: $0.name, percent: $1) }
            + [GrokReply.SharePayload(goal: name, percent: share)]
    }

    private func followUp(noun: String?, request: GrokRequest) -> String {
        if request.followUpCount > 0 {
            return "Roughly how much, and which month and year?"
        }
        if request.surface == .ask, let noun {
            return "How much is the \(noun.lowercased()), and by when?"
        }
        return "What is the target amount, and by when?"
    }

    private func answer(to question: String, context: GrokContext) -> String {
        let lowered = question.lowercased()
        if lowered.contains("split") || lowered.contains("percent") {
            return PlanExplainer.splitAnswer(context: context)
        }
        return PlanExplainer.summaryAnswer(context: context)
    }
}
