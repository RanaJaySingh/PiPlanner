import Foundation

/// A new goal proposed for the open History entry, with the one-time split that includes it.
struct EntryGoalProposal: Hashable, Sendable {
    let draft: GoalDraft
    /// Shares over the existing goals and `draft.id`, adding to 100.
    let split: Split
}

struct TransferProposal: Hashable, Sendable {
    let fromGoalID: UUID
    let toGoalID: UUID
    let amount: Decimal
}

/// What a Grok turn means after validation. Nothing here has changed the ledger yet.
enum GrokOutcome: Hashable, Sendable {
    case goalDrafts([GoalDraft])
    case entryGoal(EntryGoalProposal)
    case transfer(TransferProposal)
    case answer(String)
    case followUp(String)
    /// Too many follow-ups: hand over to the Goal form.
    case openForm
    case unsupported(String)
    /// Grok is off, has no key, or failed. Every action still works through forms.
    case unavailable
}

/// Calls Grok and validates its reply through the engine. Grok drafts; Swift decides.
struct GrokOrchestrator: Sendable {
    let provider: any GrokClientProviding

    var isAvailable: Bool { provider.makeClient() != nil }

    static func maxFollowUps(for surface: GrokSurface) -> Int {
        surface == .goalSetup ? 2 : 1
    }

    func respond(
        to utterance: String,
        surface: GrokSurface,
        ledger: Ledger,
        setupDrafts: [GoalDraft] = [],
        readyToSplit: Decimal? = nil,
        followUpCount: Int,
        asOf month: YearMonth,
        calendar: Calendar
    ) async -> GrokOutcome {
        guard let client = provider.makeClient() else { return .unavailable }

        let context = Self.context(ledger: ledger, setupDrafts: setupDrafts, readyToSplit: readyToSplit, asOf: month, calendar: calendar)
        let request = GrokRequest(utterance: utterance, surface: surface, context: context, followUpCount: followUpCount)

        let reply: GrokReply
        do {
            reply = try await client.reply(to: request)
        } catch {
            return .unavailable
        }

        let validator = ReplyValidator(ledger: ledger, surface: surface, context: context, today: month)
        let outcome = validator.outcome(for: reply)
        if case .followUp = outcome, followUpCount >= Self.maxFollowUps(for: surface) {
            return .openForm
        }
        return outcome
    }

    // MARK: - Trust boundary

    /// Goal names, percentages, amounts, dates and status only. No account data.
    static func context(
        ledger: Ledger,
        setupDrafts: [GoalDraft] = [],
        readyToSplit: Decimal? = nil,
        asOf month: YearMonth,
        calendar: Calendar
    ) -> GrokContext {
        let goalSummaries = ledger.activeGoals.map { goal -> GrokContext.GoalSummary in
            let progress = ledger.progress(of: goal.id, asOf: month, calendar: calendar)
            return GrokContext.GoalSummary(
                name: goal.name,
                saved: progress?.saved ?? 0,
                target: goal.target,
                requiredMonthly: progress?.requiredMonthly ?? 0,
                standingPercent: goal.standingPercent,
                start: goal.start.isoString,
                end: goal.end.isoString,
                status: progress.map { statusText($0.status) } ?? "on_track"
            )
        }
        let draftSummaries = setupDrafts.map { draft in
            GrokContext.GoalSummary(
                name: draft.trimmedName,
                saved: 0,
                target: draft.target,
                requiredMonthly: GoalMath.requiredMonthly(
                    target: draft.target,
                    saved: 0,
                    monthsRemaining: GoalMath.monthsRemaining(start: draft.start, end: draft.end, asOf: month)
                ),
                standingPercent: draft.standingPercent,
                start: draft.start.isoString,
                end: draft.end.isoString,
                status: "on_track"
            )
        }
        return GrokContext(
            today: month.isoString,
            goals: goalSummaries + draftSummaries,
            openEntryAmount: ledger.openEntry?.amount,
            readyToSplit: readyToSplit
        )
    }

    private static func statusText(_ status: GoalStatus) -> String {
        switch status {
        case .onTrack: "on_track"
        case .behind: "behind"
        case .ended: "ended"
        }
    }

    // MARK: - Split suggestion

    /// Opening split for new drafts: weighted by monthly need, in steps of 10%.
    static func suggestedSplit(for drafts: [GoalDraft], asOf month: YearMonth) -> [GoalDraft] {
        guard drafts.count > 1 else {
            return drafts.map { var draft = $0; draft.standingPercent = 100; return draft }
        }
        let needs = drafts.map { draft in
            GoalMath.requiredMonthly(
                target: draft.target,
                saved: 0,
                monthsRemaining: GoalMath.monthsRemaining(start: draft.start, end: draft.end, asOf: month)
            )
        }
        let split = Split.proportional(to: zip(drafts.map(\.id), needs).map { ($0, $1) }, step: 10)
        return drafts.map { draft in
            var copy = draft
            copy.standingPercent = split[draft.id]
            return copy
        }
    }
}

/// Turns a raw reply into an outcome, or a follow-up when anything fails the engine's checks.
private struct ReplyValidator {
    let ledger: Ledger
    let surface: GrokSurface
    let context: GrokContext
    let today: YearMonth

    func outcome(for reply: GrokReply) -> GrokOutcome {
        switch reply.kind {
        case .goals:
            let drafts = (reply.goals ?? []).compactMap(draft(from:))
            guard !drafts.isEmpty, drafts.count == reply.goals?.count else { return retry(reply) }
            return .goalDrafts(GrokOrchestrator.suggestedSplit(for: drafts, asOf: today))

        case .entryGoal:
            guard ledger.openEntry != nil,
                  let payload = reply.goals?.first,
                  let draft = draft(from: payload) else {
                return retry(reply)
            }
            return .entryGoal(EntryGoalProposal(draft: draft, split: entrySplit(for: draft, payload: reply.entrySplit)))

        case .transfer:
            guard let payload = reply.transfer,
                  let from = goal(named: payload.from),
                  let to = goal(named: payload.to),
                  from.id != to.id,
                  payload.amount > 0 else {
                return retry(reply)
            }
            let available = ledger.saved(from.id)
            guard payload.amount <= available else {
                return .followUp("\(from.name) has \(MoneyFormat.rupees(available)) saved. How much should move?")
            }
            return .transfer(TransferProposal(fromGoalID: from.id, toGoalID: to.id, amount: payload.amount.rounded()))

        case .answer:
            return .answer(audited(reply.message))

        case .followUp:
            return retry(reply)

        case .unsupported:
            return .unsupported(reply.message ?? "PiPlanner only plans your dedicated savings. It never moves money.")
        }
    }

    private func retry(_ reply: GrokReply) -> GrokOutcome {
        .followUp(reply.message ?? "What is the target amount, and by when?")
    }

    private func draft(from payload: GrokReply.GoalPayload) -> GoalDraft? {
        guard let end = YearMonth(isoString: payload.end) else { return nil }
        let draft = GoalDraft(
            name: payload.name,
            target: payload.target.rounded(),
            start: payload.start.flatMap(YearMonth.init(isoString:)) ?? today,
            end: end,
            standingPercent: payload.percent ?? 0
        )
        return draft.isValid ? draft : nil
    }

    private func goal(named name: String) -> Goal? {
        let lowered = name.trimmingCharacters(in: .whitespaces).lowercased()
        return ledger.activeGoals.first { $0.name.lowercased() == lowered }
            ?? ledger.activeGoals.first { $0.name.lowercased().hasPrefix(lowered) }
    }

    /// Uses Grok's split when it names every goal and adds to 100; otherwise 20% for the new goal.
    private func entrySplit(for draft: GoalDraft, payload: [GrokReply.SharePayload]?) -> Split {
        let existing = ledger.activeGoals
        if let payload {
            var split = Split()
            for share in payload {
                if share.goal.lowercased() == draft.trimmedName.lowercased() {
                    split[draft.id] = share.percent
                } else if let goal = goal(named: share.goal) {
                    split[goal.id] = share.percent
                }
            }
            let expected = Set(existing.map(\.id) + [draft.id])
            if split.isComplete, Set(split.goalIDs) == expected, split.shares.allSatisfy({ $0.percent >= 0 }) {
                return split
            }
        }
        let newShare: Decimal = existing.isEmpty ? 100 : 20
        let parts = Apportion.largestRemainder(total: 100 - newShare, weights: existing.map(\.standingPercent), unit: 5)
        return Split(zip(existing, parts).map { Split.Share(goalID: $0.id, percent: $1) } + [Split.Share(goalID: draft.id, percent: newShare)])
    }

    /// Answers may only quote rupee figures from the engine; otherwise the template answer is used.
    private func audited(_ message: String?) -> String {
        guard let message, !message.isEmpty else { return PlanExplainer.summaryAnswer(context: context) }
        let allowed = PlanExplainer.allowedAmounts(in: context)
        let quoted = PlanExplainer.quotedAmounts(in: message)
        return quoted.allSatisfy(allowed.contains) ? message : PlanExplainer.summaryAnswer(context: context)
    }
}
