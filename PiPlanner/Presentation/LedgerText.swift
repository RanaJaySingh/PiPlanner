import Foundation

/// Wording for ledger values, matching the mockup copy.
enum LedgerText {
    static func goalName(_ id: UUID, in ledger: Ledger) -> String {
        ledger.goal(id)?.name ?? String(localized: "Goal")
    }

    static func statusKind(_ status: GoalStatus) -> PiStatusChip.Kind {
        switch status {
        case .onTrack: .onTrack
        case let .behind(amount): .behind(MoneyFormat.rupees(amount))
        case .ended: .ended
        }
    }

    // MARK: - History rows

    static func historyIcon(_ entry: HistoryEntry) -> String {
        switch entry.kind {
        case .opening: PiIcon.lock
        case .credit: PiIcon.credit
        case .transfer: PiIcon.transfer
        case .goalDeleted: PiIcon.delete
        case .withdrawal: PiIcon.withdrawal
        }
    }

    /// "New credit · Custom split", "Vacation deleted", "Opening balance"…
    static func historyTitle(_ entry: HistoryEntry, in ledger: Ledger) -> String {
        switch entry.kind {
        case .opening:
            return String(localized: "Opening balance")
        case .credit:
            if entry.customSplit { return String(localized: "New credit · Custom split") }
            if entry.source == .typed { return String(localized: "New credit · Typed") }
            return String(localized: "New credit")
        case .transfer:
            return String(localized: "Transfer")
        case .goalDeleted:
            let name = entry.deletedGoalID.map { goalName($0, in: ledger) } ?? String(localized: "Goal")
            return String(localized: "\(name) deleted")
        case .withdrawal:
            return String(localized: "Withdrawal")
        }
    }

    /// The grey second line of a History row.
    static func historyDetail(_ entry: HistoryEntry, in ledger: Ledger) -> String {
        let balanceChange = "\(MoneyFormat.rupees(entry.previousBalance)) → \(MoneyFormat.rupees(entry.newBalance))"
        switch entry.kind {
        case .opening:
            return ([MoneyFormat.rupees(entry.amount)] + sliceList(entry.slices, in: ledger)).joined(separator: " · ")
        case .credit:
            if entry.isOpen {
                let toAssign = String(localized: "\(MoneyFormat.rupees(entry.amount)) to assign")
                return entry.source == .typed ? toAssign : "\(balanceChange) · \(toAssign)"
            }
            let added = MoneyFormat.signedRupees(entry.amount)
            return entry.source == .typed ? added : "\(balanceChange) · \(added)"
        case .transfer:
            guard let transfer = entry.transfer else { return MoneyFormat.rupees(entry.amount) }
            return "\(goalName(transfer.fromGoalID, in: ledger)) → \(goalName(transfer.toGoalID, in: ledger)) · \(MoneyFormat.rupees(entry.amount))"
        case .goalDeleted:
            let receivers = entry.slices.filter { $0.goalID != entry.deletedGoalID && $0.amount != 0 }
            let moved = String(localized: "\(MoneyFormat.rupees(entry.amount)) moved")
            return ([moved] + sliceList(receivers, in: ledger)).joined(separator: " · ")
        case .withdrawal:
            return ([balanceChange] + sliceList(entry.slices, in: ledger)).joined(separator: " · ")
        }
    }

    /// "Car ₹60,000", "Car −₹4,857"
    static func sliceList(_ slices: [Slice], in ledger: Ledger) -> [String] {
        slices.filter { $0.amount != 0 }.map { "\(goalName($0.goalID, in: ledger)) \(MoneyFormat.rupees($0.amount))" }
    }

    // MARK: - Hero

    /// "Last synced today, 7:42 pm" or "Last updated 5 Oct, 7:42 pm".
    static func lastUpdate(_ date: Date?, isAutomatic: Bool, now: Date, calendar: Calendar) -> String {
        guard let date else {
            return isAutomatic ? String(localized: "Not synced yet") : String(localized: "Not updated yet")
        }
        let day = calendar.isDate(date, inSameDayAs: now)
            ? String(localized: "today")
            : DateFormat.day(date, relativeTo: now, calendar: calendar)
        let time = DateFormat.time(date, calendar: calendar)
        return isAutomatic
            ? String(localized: "Last synced \(day), \(time)")
            : String(localized: "Last updated \(day), \(time)")
    }

    /// "Good evening, Rahul"
    static func greeting(name: String, now: Date, calendar: Calendar) -> String {
        let hour = calendar.component(.hour, from: now)
        switch hour {
        case 5..<12: return String(localized: "Good morning, \(name)")
        case 12..<17: return String(localized: "Good afternoon, \(name)")
        default: return String(localized: "Good evening, \(name)")
        }
    }
}
