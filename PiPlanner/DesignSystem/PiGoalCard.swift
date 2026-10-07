import SwiftUI

/// Status pill on a goal card. Status is always text, never colour alone.
struct PiStatusChip: View {
    enum Kind {
        case onTrack
        case behind(String)
        case ended
    }

    let kind: Kind

    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(foreground).frame(width: 6, height: 6)
            label
        }
        .font(PiFont.tag)
        .foregroundStyle(foreground)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(background, in: Capsule())
        .lineLimit(1)
        .fixedSize()
    }

    @ViewBuilder
    private var label: some View {
        switch kind {
        case .onTrack: Text("On track")
        case let .behind(amount): Text("Behind \(amount)")
        case .ended: Text("Ended")
        }
    }

    private var foreground: Color {
        switch kind {
        case .onTrack: PiColor.success
        case .behind: PiColor.warning
        case .ended: PiColor.inkSecondary
        }
    }

    private var background: Color {
        switch kind {
        case .onTrack: PiColor.successTint
        case .behind: PiColor.warningTint
        case .ended: PiColor.lockedFill
        }
    }
}

/// Sky strip shown while a goal edit waits for the next credit.
struct PiPendingNote: View {
    var body: some View {
        HStack(spacing: PiSpacing.s) {
            Image(systemName: PiIcon.schedule)
                .font(.system(size: 13))
                .accessibilityHidden(true)
            Text("Change saved. Applies at the next credit.")
        }
        .font(PiFont.caption)
        .foregroundStyle(PiColor.pendingText)
        .padding(.horizontal, 10)
        .padding(.vertical, PiSpacing.s)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PiColor.skyTint, in: RoundedRectangle(cornerRadius: PiRadius.field, style: .continuous))
    }
}

/// `g`: goal row in "Your Goals" with progress, required amount and share.
struct PiGoalCard: View {
    let name: String
    /// "₹85,000 of ₹10,00,000"
    let progressText: String
    let fraction: Double
    let status: PiStatusChip.Kind
    /// "Needs ₹19,063 a month"
    let needsText: Text
    /// "50% of credits"
    let shareText: Text?
    var hasPendingEdit = false
    var showsDivider = true

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: PiSpacing.m) {
                PiIconTile(systemName: PiIcon.goal(named: name), size: 44)
                VStack(alignment: .leading, spacing: PiSpacing.xxs) {
                    Text(verbatim: name)
                        .font(PiFont.rowTitle)
                        .foregroundStyle(PiColor.ink)
                    Text(verbatim: progressText)
                        .font(PiFont.caption)
                        .foregroundStyle(PiColor.inkSecondary)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                PiStatusChip(kind: status)
            }
            PiProgressBar(fraction: fraction)
            HStack {
                needsText
                Spacer(minLength: PiSpacing.s)
                if let shareText {
                    shareText
                        .fontWeight(.semibold)
                        .foregroundStyle(PiColor.inkStrong)
                }
            }
            .font(PiFont.caption)
            .foregroundStyle(PiColor.inkSecondary)
            .monospacedDigit()
            if hasPendingEdit {
                PiPendingNote()
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

/// `ban`: "New credit found" banner on the Goals tab while an entry is open.
struct PiAssignBanner: View {
    /// "₹50,000 to assign"
    let message: Text
    let onAssign: () -> Void

    var body: some View {
        HStack(spacing: PiSpacing.m) {
            PiIconTile(systemName: PiIcon.credit, style: .surface, cornerRadius: 13)
            VStack(alignment: .leading, spacing: PiSpacing.xxs) {
                Text("New credit found")
                    .font(.system(.subheadline, weight: .bold))
                    .foregroundStyle(PiColor.navy)
                message
                    .font(PiFont.body)
                    .foregroundStyle(PiColor.inkStrong)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Button("Assign now", action: onAssign)
                .font(.system(.subheadline, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .frame(minHeight: 40)
                .background(PiColor.navy, in: RoundedRectangle(cornerRadius: PiRadius.field, style: .continuous))
                .buttonStyle(.plain)
        }
        .padding(.vertical, 14)
        .padding(.leading, PiSpacing.l)
        .padding(.trailing, 14)
        .background(PiColor.skyTint, in: RoundedRectangle(cornerRadius: PiRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PiRadius.card, style: .continuous)
                .strokeBorder(PiColor.skyTintBorder, lineWidth: 1)
        }
    }
}

#Preview {
    VStack(spacing: PiSpacing.m) {
        PiAssignBanner(message: Text("₹50,000 to assign")) {}
        PiCard {
            PiSectionHeader(Text("Your Goals"))
            PiGoalCard(name: "Car", progressText: "₹75,000 of ₹10,00,000", fraction: 0.075, status: .behind("₹4,583"), needsText: Text("Needs ₹19,271 a month"), shareText: Text("50% of credits"), hasPendingEdit: true)
            PiGoalCard(name: "Emergency", progressText: "₹65,000 of ₹2,00,000", fraction: 0.325, status: .onTrack, needsText: Text("Needs ₹11,250 a month"), shareText: Text("30% of credits"), showsDivider: false)
        }
    }
    .padding()
    .background(PiColor.page)
}
