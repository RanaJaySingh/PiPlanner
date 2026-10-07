import SwiftUI

/// 4b / 4d / 11c · Mock UPI PIN pad, labelled Demo. 000000 shows the wrong-PIN state.
struct Screen04bPINView: View {
    enum Purpose {
        /// Setup: the result is the opening balance (→ 4b·2).
        case opening
        /// Later: the result goes to the Sync sheet (→ 10).
        case sync
    }

    let purpose: Purpose

    @Environment(LedgerStore.self) private var store
    @Environment(Router.self) private var router
    @State private var pin = ""
    @State private var isIncorrect = false
    @State private var isChecking = false

    private let length = DemoPINValidator.pinLength

    var body: some View {
        PiScreen {
            PiNavBar(title: "Check balance", trailing: .tag("Demo", .demo), onBack: cancel)
        } content: {
            PiCard {
                PiPINHeader(bankLabel: store.dedicatedAccount?.bankLabel ?? "", filledCount: pin.count, length: length)
                if isIncorrect {
                    PiErrorLine(text: Text("Incorrect PIN."), isCentered: true)
                }
                PiPINPad(onDigit: append, onDelete: deleteLast)
            }
        } dock: {
            Button("Check balance") {
                Task { await check() }
            }
            .buttonStyle(.piPrimary)
            .disabled(pin.count < length || isIncorrect || isChecking)
            Button("Cancel", action: cancel)
                .buttonStyle(.piLink(.navy))
        }
        .sensoryFeedback(.error, trigger: isIncorrect) { _, newValue in newValue }
    }

    private func append(_ digit: Int) {
        if isIncorrect {
            pin = ""
            isIncorrect = false
        }
        guard pin.count < length else { return }
        pin.append(String(digit))
    }

    private func deleteLast() {
        if isIncorrect {
            pin = ""
            isIncorrect = false
            return
        }
        if !pin.isEmpty { pin.removeLast() }
    }

    private func check() async {
        isChecking = true
        defer { isChecking = false }
        do {
            switch purpose {
            case .opening:
                _ = try await store.checkOpeningBalance(pin: pin)
                router.setupPath = Array(router.setupPath.dropLast()) + [.balanceRead(.pinCheck)]
            case .sync:
                let reading = try await store.checkBalance(pin: pin)
                router.pop()
                switch reading {
                case .unchanged:
                    store.showToast(String(localized: "No new credit since the last sync."))
                case let .changed(preview):
                    router.mainSheet = .sync(preview)
                }
            }
        } catch BalanceServiceError.incorrectPIN {
            isIncorrect = true
            UIAccessibility.post(notification: .announcement, argument: BalanceServiceError.incorrectPIN.message)
        } catch BalanceServiceError.notLinkedInPaytm {
            leave(with: .notLinkedInPaytm)
        } catch {
            store.showToast(userMessage(for: error))
        }
    }

    private func cancel() {
        leave(with: isIncorrect ? .incorrectPIN : nil)
    }

    /// Back to the Update balance choice; Manually is still available.
    private func leave(with notice: UpdateBalanceNotice?) {
        switch purpose {
        case .opening:
            router.setupPath.removeLast()
            router.setupSheet = .updateBalance(notice)
        case .sync:
            router.pop()
            router.mainSheet = .updateBalance(notice)
        }
    }
}

#Preview {
    NavigationStack {
        Screen04bPINView(purpose: .opening)
    }
    .environment(LedgerStore.preview())
    .environment(Router())
}
