import SwiftUI

/// `big`: caption on the left and a large amount on the right, e.g. "New amount  ₹50,000".
struct PiAmountHeadline: View {
    let label: Text
    let amount: String
    var tone: PiValueTone = .normal

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: PiSpacing.s) {
            label
                .font(PiFont.body)
                .foregroundStyle(PiColor.inkSecondary)
            Spacer(minLength: PiSpacing.s)
            Text(verbatim: amount)
                .font(PiFont.amountHeadline)
                .foregroundStyle(tone.color)
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding(.top, 6)
        .accessibilityElement(children: .combine)
    }
}

/// `bal`: the large balance figure.
struct PiBalanceText: View {
    let amount: String
    var tone: PiValueTone = .normal
    var alignment: HorizontalAlignment = .leading

    @Environment(\.piOnDarkSurface) private var onDark

    var body: some View {
        Text(verbatim: amount)
            .font(PiFont.balance)
            .foregroundStyle(onDark ? .white : tone.color)
            .contentTransition(.numericText())
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .frame(maxWidth: .infinity, alignment: Alignment(horizontal: alignment, vertical: .center))
    }
}

/// `tag`: grey pill with a lock, e.g. "Saved and locked".
struct PiLockTag: View {
    let text: Text

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: PiIcon.lock)
                .font(.system(size: 12, weight: .semibold))
                .accessibilityHidden(true)
            text
        }
        .font(PiFont.captionEmphasis)
        .foregroundStyle(PiColor.inkMuted)
        .padding(.horizontal, PiSpacing.m)
        .padding(.vertical, 6)
        .background(PiColor.lockedFill, in: RoundedRectangle(cornerRadius: PiRadius.small, style: .continuous))
    }
}

/// `ok`: green tick with a headline amount, e.g. "Balance fetched ₹1,00,000".
struct PiSuccessBlock: View {
    let title: Text
    let amount: String
    let caption: Text

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: PiIcon.check)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(PiColor.success)
                .frame(width: 64, height: 64)
                .background(PiColor.successTint, in: RoundedRectangle(cornerRadius: PiRadius.row, style: .continuous))
                .accessibilityHidden(true)
            title
                .font(.system(.callout, weight: .semibold))
                .padding(.top, 6)
            Text(verbatim: amount)
                .font(.system(size: 42, weight: .bold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            caption
                .font(PiFont.body)
                .foregroundStyle(PiColor.inkSecondary)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.vertical, PiSpacing.l)
        .accessibilityElement(children: .combine)
    }
}

/// `x`: grey block listing amounts that are already saved and will not change.
struct PiLockedBlock: View {
    struct Row: Identifiable {
        let id = UUID()
        let name: String
        let amount: String
    }

    let title: Text
    let rows: [Row]

    var body: some View {
        VStack(alignment: .leading, spacing: PiSpacing.s) {
            HStack(spacing: PiSpacing.s) {
                Image(systemName: PiIcon.lock)
                    .font(.system(size: 15, weight: .medium))
                    .accessibilityHidden(true)
                title.font(PiFont.bodyEmphasis)
            }
            .foregroundStyle(PiColor.lockedTitle)
            ForEach(rows) { row in
                HStack {
                    Text(verbatim: row.name)
                    Spacer()
                    Text(verbatim: row.amount).monospacedDigit()
                }
                .font(PiFont.body)
                .foregroundStyle(PiColor.locked)
                .padding(.leading, 26)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, PiSpacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PiColor.lockedFill, in: RoundedRectangle(cornerRadius: PiRadius.card, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

/// `bar`: sky progress bar.
struct PiProgressBar: View {
    let fraction: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(PiColor.progressTrack)
                Capsule()
                    .fill(PiEffect.progressGradient)
                    .frame(width: proxy.size.width * min(max(fraction, 0), 1))
            }
        }
        .frame(height: 8)
        .accessibilityElement()
        .accessibilityLabel("Progress")
        .accessibilityValue(Text(fraction, format: .percent.precision(.fractionLength(0))))
    }
}

#Preview {
    VStack(spacing: PiSpacing.m) {
        PiCard {
            PiValueRow(label: Text("Previous balance"), value: Text("₹1,00,000"))
            PiAmountHeadline(label: Text("New amount"), amount: "₹50,000", tone: .success)
            PiLockTag(text: Text("Saved and locked"))
            PiProgressBar(fraction: 0.065)
        }
        PiLockedBlock(title: Text("Already saved, not changing"), rows: [
            .init(name: "Car", amount: "₹60,000"),
            .init(name: "Emergency", amount: "₹40,000"),
        ])
        PiCard {
            PiSuccessBlock(title: Text("Balance fetched"), amount: "₹1,00,000", caption: Text("HDFC Bank ••4821"))
        }
    }
    .padding()
    .background(PiColor.page)
}
