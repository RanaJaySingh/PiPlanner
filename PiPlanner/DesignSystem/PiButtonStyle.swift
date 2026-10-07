import SwiftUI

/// Full-width CTA styles: `b` (primary), `o` (secondary), `bd` (destructive), `od` (destructive secondary).
struct PiButtonStyle: ButtonStyle {
    enum Kind {
        case primary
        case secondary
        case destructive
        case destructiveSecondary
    }

    let kind: Kind
    var height: CGFloat = PiSize.buttonHeight
    var font: Font = PiFont.button

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(font)
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity, minHeight: height)
            .padding(.horizontal, PiSpacing.s)
            .background(background, in: RoundedRectangle(cornerRadius: PiRadius.button, style: .continuous))
            .shadow(color: shadowColor, radius: 12, y: 12)
            .opacity(isEnabled ? (configuration.isPressed ? 0.85 : 1) : PiEffect.disabledOpacity)
            .contentShape(RoundedRectangle(cornerRadius: PiRadius.button, style: .continuous))
    }

    private var foreground: Color {
        switch kind {
        case .primary, .destructive: .white
        case .secondary: PiColor.navy
        case .destructiveSecondary: PiColor.danger
        }
    }

    private var background: Color {
        switch kind {
        case .primary: PiColor.navy
        case .secondary: PiColor.navyTint
        case .destructive: PiColor.danger
        case .destructiveSecondary: PiColor.dangerTint
        }
    }

    private var shadowColor: Color {
        guard isEnabled else { return .clear }
        switch kind {
        case .primary: return PiColor.navy.opacity(0.28)
        case .destructive: return PiColor.danger.opacity(0.28)
        case .secondary, .destructiveSecondary: return .clear
        }
    }
}

extension ButtonStyle where Self == PiButtonStyle {
    static var piPrimary: PiButtonStyle { PiButtonStyle(kind: .primary) }
    static var piSecondary: PiButtonStyle { PiButtonStyle(kind: .secondary) }
    static var piDestructive: PiButtonStyle { PiButtonStyle(kind: .destructive) }
    static var piDestructiveSecondary: PiButtonStyle { PiButtonStyle(kind: .destructiveSecondary) }
    static var piCompactPrimary: PiButtonStyle {
        PiButtonStyle(kind: .primary, height: PiSize.compactButtonHeight, font: PiFont.bodyEmphasis)
    }
    static var piCompactSecondary: PiButtonStyle {
        PiButtonStyle(kind: .secondary, height: PiSize.compactButtonHeight, font: PiFont.bodyEmphasis)
    }
}

/// Text link (`l` in the mockups). Cancel is navy, Delete is red, everything else is the link blue.
struct PiLinkButtonStyle: ButtonStyle {
    enum Tone {
        case link
        case navy
        case danger

        var color: Color {
            switch self {
            case .link: PiColor.link
            case .navy: PiColor.navy
            case .danger: PiColor.danger
            }
        }
    }

    var tone: Tone = .link

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PiFont.bodyEmphasis)
            .foregroundStyle(tone.color)
            .frame(minHeight: PiSize.minimumTapTarget)
            .contentShape(Rectangle())
            .opacity(isEnabled ? (configuration.isPressed ? 0.6 : 1) : PiEffect.disabledOpacity)
    }
}

extension ButtonStyle where Self == PiLinkButtonStyle {
    static var piLink: PiLinkButtonStyle { PiLinkButtonStyle() }
    static func piLink(_ tone: PiLinkButtonStyle.Tone) -> PiLinkButtonStyle { PiLinkButtonStyle(tone: tone) }
}

#Preview {
    VStack(spacing: PiSpacing.s) {
        Button("Set up savings") {}.buttonStyle(.piPrimary)
        Button("No, I'll update it myself") {}.buttonStyle(.piSecondary)
        Button("Delete and move ₹10,000") {}.buttonStyle(.piDestructive)
        Button("Save and lock") {}.buttonStyle(.piPrimary).disabled(true)
        Button("Reset demo") {}.buttonStyle(.piDestructiveSecondary)
        Button("Cancel") {}.buttonStyle(.piLink(.navy))
    }
    .padding()
    .background(PiColor.page)
}
