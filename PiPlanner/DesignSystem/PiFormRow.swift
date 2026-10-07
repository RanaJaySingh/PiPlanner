import SwiftUI

/// Editable `r` row in form cards: grey label on the left, an input or value on the right.
struct PiFormRow<Trailing: View>: View {
    let label: Text
    var showsDivider = true
    @ViewBuilder let trailing: Trailing

    var body: some View {
        HStack(spacing: PiSpacing.m) {
            label
                .foregroundStyle(PiColor.inkSecondary)
                .layoutPriority(1)
            Spacer(minLength: PiSpacing.m)
            trailing
                .fontWeight(.semibold)
                .foregroundStyle(PiColor.ink)
                .monospacedDigit()
                .multilineTextAlignment(.trailing)
        }
        .font(PiFont.body)
        .frame(minHeight: 46)
        .overlay(alignment: .bottom) {
            if showsDivider {
                Rectangle().fill(PiColor.hairline).frame(height: 1)
            }
        }
    }
}

/// Right-aligned rupee input for form rows, grouped as you type ("₹10,00,000").
struct PiInlineAmountField: View {
    @Binding var amount: Decimal
    let accessibilityLabel: Text

    @State private var text = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 1) {
            Text(verbatim: "₹")
            TextField(text: $text, prompt: Text(verbatim: "0")) { accessibilityLabel }
                .accessibilityLabel(accessibilityLabel)
                .keyboardType(.numberPad)
                .keyboardDoneButton()
                .focused($isFocused)
                .fixedSize()
        }
        .onAppear { text = amount > 0 ? MoneyFormat.grouped(amount) : "" }
        .onChange(of: text) { _, newValue in
            let digits = String(newValue.filter(\.isNumber).prefix(10))
            let parsed = Decimal(string: digits) ?? 0
            let formatted = digits.isEmpty ? "" : MoneyFormat.grouped(parsed)
            if formatted != newValue { text = formatted }
            if parsed != amount { amount = parsed }
        }
        .onChange(of: amount) { _, newValue in
            if !isFocused { text = newValue > 0 ? MoneyFormat.grouped(newValue) : "" }
        }
    }
}

#Preview {
    @Previewable @State var name = "Car"
    @Previewable @State var target: Decimal = 1_000_000
    PiCard(style: .form) {
        PiFormRow(label: Text("Name")) {
            TextField("Goal name", text: $name)
        }
        PiFormRow(label: Text("Target"), showsDivider: false) {
            PiInlineAmountField(amount: $target, accessibilityLabel: Text("Target"))
        }
    }
    .padding()
    .background(PiColor.page)
}
