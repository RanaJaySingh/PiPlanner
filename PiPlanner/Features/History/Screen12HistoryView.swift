import SwiftUI

/// 12 / 16a / 17b / 18b · Every entry, newest first.
struct Screen12HistoryView: View {
    @Environment(LedgerStore.self) private var store
    @Environment(Router.self) private var router

    var body: some View {
        let ledger = store.ledger
        let entries = Array(ledger.history.reversed())
        PiScreen {
            PiLargeTitle("History")
            if entries.isEmpty {
                PiCard {
                    PiBodyText("Nothing yet. Entries appear here once the opening split is locked.")
                }
            } else {
                PiCard(style: .form) {
                    ForEach(entries) { entry in
                        Button {
                            router.push(.entry(entry.id))
                        } label: {
                            PiHistoryRow(
                                icon: LedgerText.historyIcon(entry),
                                title: Text(verbatim: LedgerText.historyTitle(entry, in: ledger)),
                                detail: LedgerText.historyDetail(entry, in: ledger),
                                dateText: DateFormat.day(entry.date, relativeTo: store.now, calendar: store.calendar),
                                isOpen: entry.isOpen,
                                showsDivider: entry.id != entries.last?.id
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint(entry.isOpen ? Text("Opens the entry to assign it") : Text("Opens the saved entry"))
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        Screen12HistoryView()
    }
    .environment(LedgerStore.preview(stage: .afterTransfer))
    .environment(Router())
}
