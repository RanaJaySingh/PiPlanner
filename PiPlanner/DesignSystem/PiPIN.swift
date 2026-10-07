import SwiftUI

/// `dots`: bank label, "No money is debited." and the six PIN dots.
struct PiPINHeader: View {
    let bankLabel: String
    let filledCount: Int
    var length = 6

    var body: some View {
        VStack(spacing: PiSpacing.xs) {
            PiIconTile(systemName: PiIcon.bank, size: PiSize.iconTileLarge, cornerRadius: PiRadius.iconLarge)
            Text(verbatim: bankLabel)
                .font(.system(.headline, weight: .semibold))
                .padding(.top, PiSpacing.s)
            Text("No money is debited.")
                .font(PiFont.body)
                .foregroundStyle(PiColor.inkSecondary)
            HStack(spacing: 14) {
                ForEach(0..<length, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .strokeBorder(PiColor.navy, lineWidth: 1.5)
                        .background(
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(index < filledCount ? PiColor.navy : .clear)
                        )
                        .frame(width: 14, height: 14)
                }
            }
            .padding(.top, 18)
            .padding(.bottom, 6)
            .accessibilityElement()
            .accessibilityLabel("PIN")
            .accessibilityValue(Text("\(filledCount) of \(length) digits entered"))
        }
        .frame(maxWidth: .infinity)
    }
}

/// `pad`: 3 × 4 numeric keypad with a backspace key.
struct PiPINPad: View {
    let onDigit: (Int) -> Void
    let onDelete: () -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 3)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(1...9, id: \.self) { digit in
                key(Text(verbatim: "\(digit)")) { onDigit(digit) }
            }
            Color.clear.frame(height: 54)
            key(Text(verbatim: "0")) { onDigit(0) }
            Button(action: onDelete) {
                Image(systemName: PiIcon.backspace)
                    .font(.system(size: 22))
                    .foregroundStyle(PiColor.ink)
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delete")
        }
    }

    private func key(_ label: Text, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            label
                .font(.system(size: 26, weight: .medium))
                .foregroundStyle(PiColor.ink)
                .frame(maxWidth: .infinity, minHeight: 54)
                .background(PiColor.field, in: RoundedRectangle(cornerRadius: PiRadius.pinKey, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PiCard {
        PiPINHeader(bankLabel: "HDFC Bank ••4821", filledCount: 3)
        PiPINPad(onDigit: { _ in }, onDelete: {})
    }
    .padding()
    .background(PiColor.page)
}
