import SwiftUI

/// 20 · Settings: consent switch, demo controls, Grok mode, and Reset demo.
struct Screen20SettingsView: View {
    @Environment(LedgerStore.self) private var store
    @Environment(Router.self) private var router
    @State private var apiKey = ""
    @State private var confirmsReset = false

    var body: some View {
        PiScreen {
            PiNavBar(title: "Settings")
        } content: {
            accountsCard
            consentCard
            demoCard
            grokCard
            VStack(spacing: PiSpacing.s) {
                Button("Reset demo") { confirmsReset = true }
                    .buttonStyle(.piDestructiveSecondary)
                PiCaption("Clears goals and history and returns to Welcome.", alignment: .center)
            }
            .padding(.top, PiSpacing.s)
        }
        .confirmationDialog("Reset the demo?", isPresented: $confirmsReset, titleVisibility: .visible) {
            Button("Reset demo", role: .destructive) {
                Task {
                    await store.resetDemo()
                    router.reset()
                }
            }
        } message: {
            Text("Goals and history are cleared. Grok settings are kept.")
        }
    }

    private var accountsCard: some View {
        PiCard {
            PiSectionHeader(Text("Linked accounts"))
            ForEach(store.ledger.accounts) { account in
                PiChoiceRow(
                    icon: PiIcon.bank,
                    iconStyle: account.role == .dedicatedSavings ? .navyTint : .neutral,
                    title: Text(verbatim: account.displayName),
                    subtitle: Text(verbatim: subtitle(for: account))
                )
            }
        }
    }

    private func subtitle(for account: Account) -> String {
        guard account.role == .dedicatedSavings else {
            return String(localized: "Everyday spend. Not split across goals.")
        }
        return account.linkedInPaytm
            ? String(localized: "Dedicated savings · Linked in Paytm")
            : String(localized: "Dedicated savings · On another UPI app")
    }

    private var consentCard: some View {
        PiCard {
            PiToggleRow(title: Text("Automatic balance updates"), isOn: Binding(
                get: { store.isAutomatic },
                set: { isOn in
                    if isOn {
                        router.mainSheet = .consent
                    } else {
                        do {
                            try store.setAutomaticUpdates(false)
                        } catch {
                            store.showToast(userMessage(for: error))
                        }
                    }
                }
            ))
            PiBodyText(store.isAutomatic
                ? Text("On. PiPlanner reads this balance when you tap Sync.")
                : Text("Off. You update the balance yourself with Update balance."))
        }
    }

    private var demoCard: some View {
        PiCard {
            PiSectionHeader(Text("Demo"))
            if let account = store.dedicatedAccount {
                PiToggleRow(title: Text("Savings account linked in Paytm"), isOn: Binding(
                    get: { store.dedicatedAccount?.linkedInPaytm == true },
                    set: { store.setLinkedInPaytm($0, accountID: account.id) }
                ))
            }
            PiFormRow(label: Text("Next balance read"), showsDivider: false) {
                Picker("Next balance read", selection: Binding(
                    get: { store.nextBalanceChange },
                    set: { change in Task { await store.setNextBalanceChange(change) } }
                )) {
                    ForEach(MockBank.NextChange.allCases, id: \.self) { change in
                        Text(label(for: change)).tag(change)
                    }
                }
                .pickerStyle(.menu)
                .tint(PiColor.navy)
            }
            PiBodyText("The mock bank finds +₹50,000, then +₹20,000, unless you pick another change here.")
        }
    }

    private func label(for change: MockBank.NextChange) -> LocalizedStringKey {
        switch change {
        case .scripted: "Demo script"
        case .credit50k: "+₹50,000"
        case .credit20k: "+₹20,000"
        case .unchanged: "Unchanged"
        case .withdrawal8k: "−₹8,000"
        }
    }

    private var grokCard: some View {
        PiCard {
            PiSectionHeader(Text("Grok"))
            Picker("Grok mode", selection: Binding(
                get: { store.grokMode },
                set: { store.setGrokMode($0) }
            )) {
                Text("Mock").tag(GrokMode.mock)
                Text("Live").tag(GrokMode.live)
                Text("Off").tag(GrokMode.off)
            }
            .pickerStyle(.segmented)
            switch store.grokMode {
            case .mock:
                PiBodyText("Offline drafts for the demo sentences. No network.")
            case .live:
                if store.hasGrokAPIKey {
                    HStack {
                        PiBodyText("xAI API key saved in the Keychain.")
                        Button("Remove") { store.setGrokAPIKey(nil) }
                            .buttonStyle(.piLink(.danger))
                    }
                } else {
                    SecureField("xAI API key", text: $apiKey)
                        .textContentType(.password)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .padding(.horizontal, PiSpacing.m)
                        .frame(height: 44)
                        .background(PiColor.field, in: RoundedRectangle(cornerRadius: PiRadius.field, style: .continuous))
                    Button("Save key") {
                        store.setGrokAPIKey(apiKey)
                        apiKey = ""
                    }
                    .buttonStyle(.piCompactPrimary)
                    .disabled(apiKey.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                PiBodyText("Only goal names, amounts, dates and percentages are sent. Never account details.")
            case .off:
                PiBodyText("Grok is off. Everything still works through forms.")
            }
        }
    }
}

#Preview {
    NavigationStack {
        Screen20SettingsView()
    }
    .environment(LedgerStore.preview(stage: .afterOpening))
    .environment(Router())
}
