import SwiftUI

/// The `h` header: optional back button, centred title, and a trailing tag or icon button.
struct PiNavBar: View {
    enum Trailing {
        case none
        case tag(LocalizedStringKey, Tone)
        case icon(systemName: String, accessibilityLabel: LocalizedStringKey, action: () -> Void)
    }

    enum Tone {
        /// "Step 1 of 3"
        case step
        /// "Demo"
        case demo
        /// "Assign now"
        case assign
        /// "Typed" and other neutral labels.
        case neutral

        var background: Color {
            switch self {
            case .step: PiColor.surface
            case .demo: PiColor.warningTint
            case .assign: PiColor.assignPill
            case .neutral: PiColor.lockedFill
            }
        }

        var foreground: Color {
            switch self {
            case .step, .neutral: PiColor.inkMuted
            case .demo: PiColor.demoTag
            case .assign: PiColor.navy
            }
        }
    }

    let title: LocalizedStringKey
    var showsBack = true
    var trailing: Trailing = .none
    /// Overrides the default `dismiss()` back behaviour.
    var onBack: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        HStack(spacing: PiSpacing.s) {
            leading
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(title)
                .font(PiFont.navTitle)
                .foregroundStyle(PiColor.ink)
                .lineLimit(1)
                .fixedSize()
                .accessibilityAddTraits(.isHeader)
            trailingView
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(height: 56)
    }

    @ViewBuilder
    private var leading: some View {
        if showsBack {
            PiNavIconButton(systemName: PiIcon.back, accessibilityLabel: "Back") {
                if let onBack { onBack() } else { dismiss() }
            }
        } else {
            placeholder
        }
    }

    /// Keeps the title centred when a side is empty; `EmptyView` takes no width in the `HStack`.
    private var placeholder: some View {
        Color.clear.frame(width: PiSize.navButton, height: PiSize.navButton)
    }

    @ViewBuilder
    private var trailingView: some View {
        switch trailing {
        case .none:
            placeholder
        case let .tag(text, tone):
            Text(text)
                .font(PiFont.tag)
                .foregroundStyle(tone.foreground)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(tone.background, in: RoundedRectangle(cornerRadius: PiRadius.small, style: .continuous))
                .lineLimit(1)
        case let .icon(systemName, label, action):
            PiNavIconButton(systemName: systemName, accessibilityLabel: label, action: action)
        }
    }
}

/// White 40 pt rounded icon button used in headers.
struct PiNavIconButton: View {
    let systemName: String
    let accessibilityLabel: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(PiColor.navy)
                .frame(width: PiSize.navButton, height: PiSize.navButton)
                .background(PiColor.surface, in: RoundedRectangle(cornerRadius: PiRadius.tile, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: PiRadius.tile, style: .continuous)
                        .strokeBorder(PiEffect.cardHairline, lineWidth: 1)
                }
                .frame(minWidth: PiSize.minimumTapTarget, minHeight: PiSize.minimumTapTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(accessibilityLabel))
    }
}

#Preview {
    VStack {
        PiNavBar(title: "Accounts", trailing: .tag("Step 1 of 3", .step))
        PiNavBar(title: "Check balance", trailing: .tag("Demo", .demo))
        PiNavBar(title: "New credit", trailing: .tag("Assign now", .assign))
        PiNavBar(title: "Car", trailing: .icon(systemName: PiIcon.edit, accessibilityLabel: "Edit goal") {})
        PiNavBar(title: "Balance", showsBack: false, trailing: .tag("Step 2 of 3", .step))
    }
    .padding(.horizontal, PiSpacing.screen)
    .background(PiColor.page)
}
