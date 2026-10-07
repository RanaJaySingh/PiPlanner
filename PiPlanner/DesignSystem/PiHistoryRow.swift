import SwiftUI

/// `hrow`: one History entry. Open entries show "Assign now"; saved entries show a lock.
struct PiHistoryRow: View {
    let icon: String
    let title: Text
    let detail: String
    let dateText: String
    let isOpen: Bool
    var showsDivider = true

    var body: some View {
        HStack(alignment: .top, spacing: PiSpacing.m) {
            PiIconTile(systemName: icon, style: isOpen ? .navyFilled : .locked, cornerRadius: 13)
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: PiSpacing.s) {
                    title
                        .font(.system(.subheadline, weight: .semibold))
                        .foregroundStyle(PiColor.ink)
                    Spacer(minLength: PiSpacing.s)
                    Text(verbatim: dateText)
                        .font(PiFont.caption)
                        .foregroundStyle(PiColor.inkSecondary)
                        .lineLimit(1)
                }
                Text(verbatim: detail)
                    .font(PiFont.caption)
                    .foregroundStyle(PiColor.inkSecondary)
                    .monospacedDigit()
                    .fixedSize(horizontal: false, vertical: true)
                if isOpen {
                    Text("Assign now")
                        .font(PiFont.tag)
                        .foregroundStyle(PiColor.navy)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(PiColor.assignPill, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                        .padding(.top, 6)
                }
            }
            if !isOpen {
                Image(systemName: PiIcon.lock)
                    .font(.system(size: 13))
                    .foregroundStyle(PiColor.chevron)
                    .padding(.top, 2)
                    .accessibilityLabel("Saved")
            }
        }
        .padding(.vertical, 14)
        .overlay(alignment: .bottom) {
            if showsDivider {
                Rectangle().fill(PiColor.hairline).frame(height: 1)
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    PiCard(style: .form) {
        PiHistoryRow(icon: PiIcon.credit, title: Text("New credit"), detail: "₹1,50,000 → ₹2,00,000 · ₹50,000 to assign", dateText: "Today", isOpen: true)
        PiHistoryRow(icon: PiIcon.transfer, title: Text("Transfer"), detail: "Emergency → Car · ₹5,000", dateText: "5 Oct", isOpen: false)
        PiHistoryRow(icon: PiIcon.lock, title: Text("Opening balance"), detail: "₹1,00,000 · Car ₹60,000 · Emergency ₹40,000", dateText: "1 Oct", isOpen: false, showsDivider: false)
    }
    .padding()
    .background(PiColor.page)
}
