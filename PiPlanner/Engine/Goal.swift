import Foundation

struct Goal: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    var name: String
    var target: Decimal
    var start: YearMonth
    var end: YearMonth
    /// Only suggests the split of the NEXT new amount.
    var standingPercent: Decimal
    /// Held here and applied when the next entry is written.
    var pendingEdit: GoalEdit?
    /// Kept so old entries still resolve a name.
    var isDeleted = false

    init(draft: GoalDraft, standingPercent: Decimal) {
        id = draft.id
        name = draft.trimmedName
        target = draft.target
        start = draft.start
        end = draft.end
        self.standingPercent = standingPercent
    }

    mutating func apply(_ edit: GoalEdit) {
        name = edit.name
        target = edit.target
        start = edit.start
        end = edit.end
        standingPercent = edit.standingPercent
    }

    /// The goal as it will be once its pending edit applies.
    var effective: Goal {
        guard let pendingEdit else { return self }
        var copy = self
        copy.apply(pendingEdit)
        copy.pendingEdit = nil
        return copy
    }
}

/// A complete replacement of a goal's editable fields.
struct GoalEdit: Hashable, Codable, Sendable {
    var name: String
    var target: Decimal
    var start: YearMonth
    var end: YearMonth
    var standingPercent: Decimal
}

/// Goal fields before they are saved, from the form, Grok, or setup.
struct GoalDraft: Identifiable, Hashable, Codable, Sendable {
    enum Issue: Hashable, Codable, Sendable {
        case emptyName
        case nonPositiveTarget
        case endNotAfterStart
    }

    var id = UUID()
    var name: String
    var target: Decimal
    var start: YearMonth
    var end: YearMonth
    var standingPercent: Decimal = 0

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var issues: [Issue] {
        var issues: [Issue] = []
        if trimmedName.isEmpty { issues.append(.emptyName) }
        if target <= 0 { issues.append(.nonPositiveTarget) }
        if end <= start { issues.append(.endNotAfterStart) }
        return issues
    }

    var isValid: Bool { issues.isEmpty }

    var edit: GoalEdit {
        GoalEdit(name: trimmedName, target: target, start: start, end: end, standingPercent: standingPercent)
    }
}

extension GoalDraft {
    /// Starts from a goal's effective values, so a second edit builds on a pending one.
    init(goal: Goal) {
        let source = goal.effective
        self.init(
            id: goal.id,
            name: source.name,
            target: source.target,
            start: source.start,
            end: source.end,
            standingPercent: source.standingPercent
        )
    }
}
