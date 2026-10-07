import SwiftUI

/// `H`: large page title used on setup steps and tab roots.
struct PiLargeTitle: View {
    private let text: Text

    init(_ key: LocalizedStringKey) { text = Text(key) }
    init(_ text: Text) { self.text = text }

    var body: some View {
        text
            .font(PiFont.largeTitle)
            .foregroundStyle(PiColor.ink)
            .padding(.horizontal, 6)
            .padding(.top, PiSpacing.s)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }
}

/// `t`: body copy. Secondary grey on light surfaces, translucent white on the hero.
struct PiBodyText: View {
    private let text: Text
    var tone: Tone = .secondary

    enum Tone { case secondary, primary }

    @Environment(\.piOnDarkSurface) private var onDark

    init(_ key: LocalizedStringKey, tone: Tone = .secondary) {
        text = Text(key)
        self.tone = tone
    }

    init(_ text: Text, tone: Tone = .secondary) {
        self.text = text
        self.tone = tone
    }

    var body: some View {
        text
            .font(PiFont.body)
            .foregroundStyle(color)
            .lineSpacing(2)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var color: Color {
        if onDark { return .white.opacity(0.75) }
        return tone == .primary ? PiColor.ink : PiColor.inkSecondary
    }
}

/// `c`: small caption, optionally centred.
struct PiCaption: View {
    private let text: Text
    var alignment: TextAlignment = .leading

    init(_ key: LocalizedStringKey, alignment: TextAlignment = .leading) {
        text = Text(key)
        self.alignment = alignment
    }

    init(_ text: Text, alignment: TextAlignment = .leading) {
        self.text = text
        self.alignment = alignment
    }

    var body: some View {
        text
            .font(PiFont.caption)
            .foregroundStyle(PiColor.inkSecondary)
            .multilineTextAlignment(alignment)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: alignment == .center ? .center : .leading)
    }
}

/// `ttl`: bold statement inside a card, e.g. "This releases ₹10,000."
struct PiStatement: View {
    private let text: Text
    var isWarning = false

    init(_ text: Text, isWarning: Bool = false) {
        self.text = text
        self.isWarning = isWarning
    }

    var body: some View {
        text
            .font(PiFont.heading)
            .foregroundStyle(isWarning ? PiColor.warning : PiColor.ink)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// `sec`: card section title with an optional trailing caption or link.
struct PiSectionHeader: View {
    private let title: Text
    private let trailing: Text?

    init(_ title: Text, trailing: Text? = nil) {
        self.title = title
        self.trailing = trailing
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: PiSpacing.s) {
            title
                .font(PiFont.section)
                .foregroundStyle(PiColor.ink)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: PiSpacing.s)
            if let trailing {
                trailing
                    .font(PiFont.captionEmphasis)
                    .foregroundStyle(PiColor.link)
            }
        }
        .frame(minHeight: 24)
    }
}

/// `st`: sheet title with an optional close button.
struct PiSheetHeader: View {
    private let title: Text
    private let onClose: (() -> Void)?

    init(_ title: Text, onClose: (() -> Void)? = nil) {
        self.title = title
        self.onClose = onClose
    }

    var body: some View {
        HStack(alignment: .center, spacing: PiSpacing.m) {
            title
                .font(PiFont.sheetTitle)
                .foregroundStyle(PiColor.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 0)
            if let onClose {
                Button(action: onClose) {
                    Image(systemName: PiIcon.close)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(PiColor.inkMuted)
                        .frame(width: 36, height: 36)
                        .background(PiColor.field, in: RoundedRectangle(cornerRadius: PiRadius.field, style: .continuous))
                        .frame(minWidth: PiSize.minimumTapTarget, minHeight: PiSize.minimumTapTarget)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")
            }
        }
    }
}

#Preview {
    VStack(spacing: PiSpacing.m) {
        PiLargeTitle("What are you planning for?")
        PiBodyText("Describe your goals in a sentence.")
        PiCaption("Locked amounts never change.", alignment: .center)
        PiStatement(Text("This releases ₹10,000."))
        PiSectionHeader(Text("Your Goals"), trailing: Text("This credit only"))
        PiSheetHeader(Text("Update balance")) {}
    }
    .padding()
}
