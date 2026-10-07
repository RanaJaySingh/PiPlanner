import SwiftUI

/// `amt`: large centred rupee field with Indian digit grouping as you type.
struct PiAmountField: View {
    @Binding var amount: Decimal
    var accessibilityLabel: LocalizedStringKey = "Amount in rupees"

    @State private var text = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: PiSpacing.xs) {
            Text(verbatim: "₹")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(PiColor.inkPlaceholder)
            TextField(text: $text, prompt: Text(verbatim: "0")) {
                Text(accessibilityLabel)
            }
            .accessibilityLabel(Text(accessibilityLabel))
            .font(PiFont.amountEntry)
            .keyboardType(.numberPad)
            .keyboardDoneButton()
            .focused($isFocused)
            .fixedSize()
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 18)
        .padding(.bottom, PiSpacing.s)
        .contentShape(Rectangle())
        .onTapGesture { isFocused = true }
        .onAppear {
            text = amount > 0 ? MoneyFormat.grouped(amount) : ""
            isFocused = amount == 0
        }
        .onChange(of: text) { _, newValue in
            let digits = String(newValue.filter(\.isNumber).prefix(10))
            let parsed = Decimal(string: digits) ?? 0
            let formatted = digits.isEmpty ? "" : MoneyFormat.grouped(parsed)
            if formatted != newValue { text = formatted }
            if parsed != amount { amount = parsed }
        }
    }
}

/// Percentage entry box used in split rows (`p` with a field).
struct PiPercentField: View {
    @Binding var value: Decimal
    let accessibilityLabel: Text

    @State private var text = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: PiSpacing.xxs) {
            TextField(text: $text, prompt: Text(verbatim: "0")) { accessibilityLabel }
                .accessibilityLabel(accessibilityLabel)
                .keyboardType(.decimalPad)
                .keyboardDoneButton()
                .multilineTextAlignment(.trailing)
                .focused($isFocused)
                .font(.system(.headline, weight: .semibold))
                .monospacedDigit()
            Text(verbatim: "%")
                .font(PiFont.body)
                .foregroundStyle(PiColor.inkSecondary)
        }
        .padding(.horizontal, PiSpacing.m)
        .frame(width: 92, height: 44)
        .background(PiColor.field, in: RoundedRectangle(cornerRadius: PiRadius.field, style: .continuous))
        .onAppear { text = PercentFormat.editable(value) }
        .onChange(of: text) { _, newValue in
            let cleaned = newValue.filter { $0.isNumber || $0 == "." }
            if cleaned != newValue { text = cleaned; return }
            let parsed = Decimal(string: cleaned, locale: Locale(identifier: "en_US_POSIX")) ?? 0
            let clamped = min(max(parsed, 0), 100)
            if clamped != value { value = clamped }
        }
        .onChange(of: value) { _, newValue in
            if !isFocused { text = PercentFormat.editable(newValue) }
        }
    }
}

/// `inp`: chat composer with a send button.
struct PiComposer: View {
    @Binding var text: String
    let placeholder: LocalizedStringKey
    var isEnabled = true
    let onSend: () -> Void

    @FocusState private var isFocused: Bool

    private var canSend: Bool {
        isEnabled && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        HStack(spacing: PiSpacing.s) {
            TextField(placeholder, text: $text, axis: .vertical)
                .font(.system(.subheadline))
                .lineLimit(1...4)
                .submitLabel(.send)
                .onSubmit { if canSend { send() } }
                .focused($isFocused)
                .disabled(!isEnabled)
                .accessibilityIdentifier("composer")
            Button(action: send) {
                Image(systemName: PiIcon.send)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(PiColor.navy, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
            .accessibilityLabel("Send")
        }
        .padding(.leading, PiSpacing.l)
        .padding([.vertical, .trailing], 6)
        .background(PiColor.surface, in: RoundedRectangle(cornerRadius: PiRadius.button, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PiRadius.button, style: .continuous)
                .strokeBorder(PiEffect.cardHairline, lineWidth: 1)
        }
        .opacity(isEnabled ? 1 : PiEffect.disabledOpacity)
    }

    /// Grok replies with a card to confirm, so the keyboard closes to keep it in view.
    private func send() {
        isFocused = false
        onSend()
    }
}

#Preview {
    @Previewable @State var amount: Decimal = 50_000
    @Previewable @State var percent: Decimal = 60
    @Previewable @State var message = ""
    VStack(spacing: PiSpacing.l) {
        PiCard { PiAmountField(amount: $amount) }
        PiPercentField(value: $percent, accessibilityLabel: Text("Car share"))
        PiComposer(text: $message, placeholder: "Describe a goal") {}
    }
    .padding()
    .background(PiColor.page)
}
