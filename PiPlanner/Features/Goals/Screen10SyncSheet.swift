import SwiftUI

/// 10 / 10b / 20c · What the balance read found. Continue writes the open entry or opens the withdrawal.
struct Screen10SyncSheet: View {
    let preview: SyncPreview

    @Environment(LedgerStore.self) private var store
    @Environment(Router.self) private var router
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        PiSheet {
            PiSheetHeader(Text("Balance sync")) { dismiss() }
            VStack(spacing: 0) {
                PiValueRow(label: Text("Previous balance"), value: Text(verbatim: MoneyFormat.rupees(preview.previous)))
                PiValueRow(label: Text("Fetched balance"), value: Text(verbatim: MoneyFormat.rupees(preview.fetched)))
                PiAmountHeadline(
                    label: preview.isIncrease ? Text("New amount") : Text("Went down by"),
                    amount: MoneyFormat.signedRupees(preview.delta),
                    tone: preview.isIncrease ? .success : .warning
                )
            }
            if !preview.isIncrease {
                PiWarningBanner(text: Text("Your savings balance went down by \(MoneyFormat.rupees(-preview.delta))."))
            } else if preview.isCatchUp {
                PiBodyText("Anything not typed in the meantime arrives as one amount.")
            }
            Button("Continue", action: proceed)
                .buttonStyle(.piPrimary)
        }
    }

    private func proceed() {
        if preview.isIncrease {
            do {
                let entryID = try store.beginCredit(from: preview)
                router.mainSheet = nil
                router.push(.entry(entryID))
            } catch {
                store.showToast(userMessage(for: error))
            }
        } else {
            router.mainSheet = nil
            router.push(.withdrawal(WithdrawalRequest(amount: -preview.delta, source: preview.source, fetchedBalance: preview.fetched)))
        }
    }
}

#Preview("10") {
    Color.clear.sheet(isPresented: .constant(true)) {
        Screen10SyncSheet(preview: SyncPreview(previous: 100_000, fetched: 150_000, source: .fetched, isCatchUp: false))
    }
    .environment(LedgerStore.preview(stage: .afterOpening))
    .environment(Router())
}

#Preview("10b") {
    Color.clear.sheet(isPresented: .constant(true)) {
        Screen10SyncSheet(preview: SyncPreview(previous: 150_000, fetched: 142_000, source: .fetched, isCatchUp: false))
    }
    .environment(LedgerStore.preview(stage: .afterCustomCredit))
    .environment(Router())
}
