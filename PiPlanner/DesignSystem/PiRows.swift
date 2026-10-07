import SwiftUI

/// Colour of a value or subtitle in rows (`r` and `p` tones in the mockups).
enum PiValueTone {
    case normal
    case success
    case warning
    case locked
    case secondary

    var color: Color {
        switch self {
        case .normal: PiColor.ink
        case .success: PiColor.success
        case .warning: PiColor.warning
        case .locked: PiColor.locked
        case .secondary: PiColor.inkSecondary
        }
    }
}

/// `r`: label on the left, value on the right, hairline below.
struct PiValueRow: View {
    let label: Text
    let value: Text
    var tone: PiValueTone = .normal
    var showsDivider = true

    var body: some View {
        HStack(spacing: PiSpacing.m) {
            label
                .foregroundStyle(tone == .locked ? PiColor.locked : PiColor.inkSecondary)
            Spacer(minLength: PiSpacing.m)
            value
                .fontWeight(.semibold)
                .monospacedDigit()
                .foregroundStyle(tone.color)
                .multilineTextAlignment(.trailing)
        }
        .font(PiFont.body)
        .frame(minHeight: 46)
        .overlay(alignment: .bottom) {
            if showsDivider {
                Rectangle().fill(PiColor.hairline).frame(height: 1)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// Accessory on the trailing edge of a `PiChoiceRow`.
enum PiRowAccessory {
    case none
    case chevron
    case toggle(Binding<Bool>)
}

/// `k`: icon tile, title and subtitle, with an optional toggle or chevron.
struct PiChoiceRow: View {
    let icon: String
    var iconStyle: PiIconTile.Style = .navyTint
    let title: Text
    var subtitle: Text?
    /// Shows the title as a large amount, used when the row headline is money.
    var titleIsAmount = false
    /// Rows outside cards sit on a light grey background.
    var isInset = false
    var accessory: PiRowAccessory = .none

    var body: some View {
        HStack(spacing: PiSpacing.m) {
            PiIconTile(systemName: icon, style: iconStyle, size: PiSize.iconTileLarge, cornerRadius: PiRadius.iconLarge)
            VStack(alignment: .leading, spacing: PiSpacing.xxs) {
                title
                    .font(titleIsAmount ? PiFont.amountHeadline : PiFont.rowTitle)
                    .foregroundStyle(PiColor.ink)
                    .monospacedDigit()
                if let subtitle {
                    subtitle
                        .font(PiFont.caption)
                        .foregroundStyle(PiColor.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            accessoryView
        }
        .padding(isInset ? 14 : 0)
        .background {
            if isInset {
                RoundedRectangle(cornerRadius: PiRadius.row, style: .continuous).fill(PiColor.fieldSubtle)
            }
        }
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var accessoryView: some View {
        switch accessory {
        case .none:
            EmptyView()
        case .chevron:
            Image(systemName: PiIcon.chevron)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(PiColor.chevron)
                .accessibilityHidden(true)
        case let .toggle(isOn):
            Toggle("", isOn: isOn)
                .labelsHidden()
                .toggleStyle(.pi)
        }
    }
}

/// `tg`: label with a toggle on a light grey strip.
struct PiToggleRow: View {
    let title: Text
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            title
                .font(PiFont.bodyEmphasis)
                .foregroundStyle(PiColor.ink)
        }
        .toggleStyle(.pi)
        .padding(.horizontal, PiSpacing.m)
        .padding(.vertical, 10)
        .background(PiColor.fieldSubtle, in: RoundedRectangle(cornerRadius: PiRadius.tile, style: .continuous))
    }
}

/// Rounded-square switch from the mockups.
struct PiToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            withAnimation(.snappy(duration: 0.2)) { configuration.isOn.toggle() }
        } label: {
            HStack(spacing: PiSpacing.m) {
                configuration.label
                    .frame(maxWidth: .infinity, alignment: .leading)
                RoundedRectangle(cornerRadius: PiRadius.small, style: .continuous)
                    .fill(configuration.isOn ? PiColor.navy : PiColor.toggleOff)
                    .frame(width: 48, height: 30)
                    .overlay(alignment: configuration.isOn ? .trailing : .leading) {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(.white)
                            .frame(width: 24, height: 24)
                            .shadow(color: .black.opacity(0.18), radius: 1.5, y: 1)
                            .padding(3)
                    }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityRepresentation {
            Toggle(isOn: configuration.$isOn) { configuration.label }
        }
    }
}

extension ToggleStyle where Self == PiToggleStyle {
    static var pi: PiToggleStyle { PiToggleStyle() }
}

/// `ck`: green check with a line of copy.
struct PiCheckRow: View {
    let text: Text

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: PiIcon.check)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(PiColor.success)
                .frame(width: 22, height: 22)
                .background(PiColor.successTint, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                .alignmentGuide(.firstTextBaseline) { $0[VerticalAlignment.center] + 5 }
                .accessibilityHidden(true)
            text
                .font(.system(.subheadline))
                .foregroundStyle(PiColor.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    @Previewable @State var on = true
    VStack(spacing: PiSpacing.m) {
        PiCard {
            PiChoiceRow(icon: PiIcon.bank, title: Text("₹1,00,000"), subtitle: Text("Savings · HDFC ••4821"), titleIsAmount: true)
            PiToggleRow(title: Text("Dedicated savings"), isOn: $on)
        }
        PiChoiceRow(icon: PiIcon.edit, title: Text("Manually"), subtitle: Text("Type the amount yourself"), isInset: true, accessory: .chevron)
        PiCard(style: .form) {
            PiValueRow(label: Text("Previous balance"), value: Text("₹1,00,000"))
            PiValueRow(label: Text("Car"), value: Text("₹85,000 → ₹90,000"), tone: .success)
        }
        PiCheckRow(text: Text("Reads only this balance"))
    }
    .padding()
    .background(PiColor.page)
}
