import SwiftUI

/// `p`: a goal row inside a split, with either an editable percentage or a fixed trailing value.
struct PiSplitRow: View {
    enum Trailing {
        case none
        case percent(Binding<Decimal>)
        /// A fixed value; `isLocked` greys the icon, as for amounts that are already saved.
        case fixed(String, isLocked: Bool = false)
    }

    let name: String
    let detail: Text
    var detailTone: PiValueTone = .secondary
    var trailing: Trailing = .none
    var showsDivider = true

    var body: some View {
        HStack(spacing: PiSpacing.m) {
            PiIconTile(systemName: PiIcon.goal(named: name), style: isLocked ? .locked : .navyTint, cornerRadius: 13)
            VStack(alignment: .leading, spacing: PiSpacing.xxs) {
                Text(verbatim: name)
                    .font(PiFont.rowTitle)
                    .foregroundStyle(PiColor.ink)
                detail
                    .font(PiFont.captionEmphasis)
                    .foregroundStyle(detailTone.color)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            trailingView
        }
        .frame(minHeight: 64)
        .overlay(alignment: .bottom) {
            if showsDivider {
                Rectangle().fill(PiColor.hairline).frame(height: 1)
            }
        }
    }

    private var isLocked: Bool {
        if case let .fixed(_, locked) = trailing { return locked }
        return false
    }

    @ViewBuilder
    private var trailingView: some View {
        switch trailing {
        case .none:
            EmptyView()
        case let .percent(value):
            PiPercentField(value: value, accessibilityLabel: Text("\(name) share"))
        case let .fixed(text, locked):
            Text(verbatim: text)
                .font(.system(.callout, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(locked ? PiColor.inkMuted : PiColor.ink)
                .contentTransition(.numericText())
        }
    }
}

/// `tot` / `terr`: running total, green at 100% and red otherwise.
struct PiTotalLine: View {
    let total: Decimal

    var body: some View {
        Group {
            if total == 100 {
                Text("Total \(PercentFormat.percent(total))")
                    .foregroundStyle(PiColor.success)
            } else if total < 100 {
                Text("Total \(PercentFormat.percent(total)). Assign the remaining \(PercentFormat.percent(100 - total)).")
                    .foregroundStyle(PiColor.danger)
            } else {
                Text("Total \(PercentFormat.percent(total)). Remove \(PercentFormat.percent(total - 100)).")
                    .foregroundStyle(PiColor.danger)
            }
        }
        .font(.system(.subheadline, weight: .bold))
        .monospacedDigit()
        .padding(.top, PiSpacing.xs)
        .accessibilityAddTraits(.updatesFrequently)
    }
}

#Preview {
    @Previewable @State var car: Decimal = 50
    @Previewable @State var emergency: Decimal = 30
    PiCard {
        PiSectionHeader(Text("Split ₹50,000"), trailing: Text("This credit only"))
        PiSplitRow(name: "Car", detail: Text("₹15,000 · ₹4,583 behind this month"), detailTone: .success, trailing: .percent($car))
        PiSplitRow(name: "Emergency", detail: Text("₹15,000"), detailTone: .success, trailing: .percent($emergency))
        PiSplitRow(name: "Vacation", detail: Text("20% of ₹50,000"), trailing: .fixed("₹10,000"))
        PiTotalLine(total: car + emergency)
    }
    .padding()
    .background(PiColor.page)
}
