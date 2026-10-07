import SwiftUI

/// 4 / 4c / 4e / 11a · Manually, or Balance sync with the UPI PIN.
struct Screen04UpdateBalanceSheet: View {
    enum Context {
        case setup
        case main
    }

    let context: Context
    let notice: UpdateBalanceNotice?

    @Environment(LedgerStore.self) private var store
    @Environment(Router.self) private var router
    @State private var showsNotLinked = false

    private static let notLinkedDelay: Duration = .seconds(1.6)

    var body: some View {
        PiSheet {
            if notice == .incorrectPIN {
                PiErrorLine(text: Text("Incorrect PIN. Try again or enter it manually."))
            }
            PiSheetHeader(Text("Update balance"))
            Button(action: openManual) {
                PiChoiceRow(
                    icon: PiIcon.edit,
                    iconStyle: .navyFilled,
                    title: Text("Manually"),
                    subtitle: Text("Type the amount yourself"),
                    isInset: true
                )
            }
            .buttonStyle(.plain)
            Button(action: openBalanceSync) {
                PiChoiceRow(
                    icon: PiIcon.sync,
                    iconStyle: .navyFilled,
                    title: Text("Balance sync"),
                    subtitle: Text("Check with your UPI PIN"),
                    isInset: true
                )
            }
            .buttonStyle(.plain)
            if showsNotLinked || notice == .notLinkedInPaytm {
                PiWarningBanner(text: Text("This account is not linked in Paytm, so we can't check it. Enter the balance instead."))
                    .transition(.opacity)
            }
        }
        .animation(.snappy, value: showsNotLinked)
        .task(id: showsNotLinked) {
            guard showsNotLinked else { return }
            try? await Task.sleep(for: Self.notLinkedDelay)
            guard !Task.isCancelled else { return }
            openManual()
        }
    }

    private func openManual() {
        switch context {
        case .setup:
            router.setupSheet = nil
            router.setupPath.append(.manualOpening)
        case .main:
            router.mainSheet = nil
            router.push(.amountEntry(.added))
        }
    }

    private func openBalanceSync() {
        guard store.dedicatedAccount?.linkedInPaytm == true else {
            showsNotLinked = true
            UIAccessibility.post(notification: .announcement, argument: BalanceServiceError.notLinkedInPaytm.message)
            return
        }
        switch context {
        case .setup:
            router.setupSheet = nil
            router.setupPath.append(.pin)
        case .main:
            router.mainSheet = nil
            router.push(.pin)
        }
    }
}

#Preview("4") {
    Color.clear.sheet(isPresented: .constant(true)) {
        Screen04UpdateBalanceSheet(context: .setup, notice: nil)
    }
    .environment(LedgerStore.preview())
    .environment(Router())
}

#Preview("4e") {
    Color.clear.sheet(isPresented: .constant(true)) {
        Screen04UpdateBalanceSheet(context: .setup, notice: .incorrectPIN)
    }
    .environment(LedgerStore.preview())
    .environment(Router())
}
