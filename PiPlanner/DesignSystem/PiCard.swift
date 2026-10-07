import SwiftUI

/// Content blocks from the mockups: `[` card, `[e` form card, `[s` info card, `[h` hero card.
struct PiCard<Content: View>: View {
    enum Style {
        /// White card with hairline shadow.
        case standard
        /// Form-style card with tight vertical padding for value rows.
        case form
        /// Sky-tinted informational card.
        case info
        /// Navy hero with a cyan glow.
        case hero
        /// Light grey inset used inside sheets, where cards have no shadow.
        case inset
    }

    var style: Style = .standard
    var spacing: CGFloat = PiSpacing.m
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: style == .form ? 0 : spacing) {
            content
        }
        .padding(padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { background }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .modifier(CardShadow(isVisible: style == .standard || style == .form))
        .environment(\.piOnDarkSurface, style == .hero)
    }

    private var padding: EdgeInsets {
        switch style {
        case .form: EdgeInsets(top: PiSpacing.xs, leading: 18, bottom: PiSpacing.xs, trailing: 18)
        case .hero: EdgeInsets(top: PiSpacing.xl, leading: PiSpacing.xl, bottom: PiSpacing.xl, trailing: PiSpacing.xl)
        default: EdgeInsets(top: 18, leading: 18, bottom: 18, trailing: 18)
        }
    }

    private var cornerRadius: CGFloat {
        style == .hero ? PiRadius.hero : PiRadius.card
    }

    @ViewBuilder
    private var background: some View {
        switch style {
        case .standard, .form: PiColor.surface
        case .info: PiColor.skyTint
        case .hero: PiEffect.heroBackground
        case .inset: PiColor.fieldSubtle
        }
    }
}

private struct CardShadow: ViewModifier {
    let isVisible: Bool

    func body(content: Content) -> some View {
        if isVisible {
            content
                .overlay {
                    RoundedRectangle(cornerRadius: PiRadius.card, style: .continuous)
                        .strokeBorder(PiEffect.cardHairline, lineWidth: 1)
                }
                .shadow(color: PiEffect.cardShadowColor, radius: 1, y: 1)
        } else {
            content
        }
    }
}

extension EnvironmentValues {
    /// True inside the navy hero card so text components switch to white.
    @Entry var piOnDarkSurface: Bool = false
}

#Preview {
    ScrollView {
        VStack(spacing: PiSpacing.m) {
            PiCard(style: .hero) {
                Text("Dedicated savings · HDFC ••4821").font(PiFont.body).foregroundStyle(.white.opacity(0.75))
                Text("₹1,50,000").font(PiFont.balance).foregroundStyle(.white)
            }
            PiCard { Text("Standard card") }
            PiCard(style: .info) { Text("Info card") }
            PiCard(style: .inset) { Text("Inset card") }
        }
        .padding(PiSpacing.screen)
    }
    .background(PiColor.page)
}
