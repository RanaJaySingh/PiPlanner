import SwiftUI

/// `i` + `hero`: the Welcome hero with a goals illustration.
struct PiWelcomeHero: View {
    var body: some View {
        PiCard(style: .hero, spacing: 6) {
            illustration
                .padding(.bottom, PiSpacing.s)
            VStack(alignment: .leading, spacing: PiSpacing.s) {
                Text(verbatim: "PIPLANNER")
                    .font(PiFont.tag)
                    .tracking(1.2)
                    .foregroundStyle(PiColor.skyHighlight)
                Text("Every Rupee Has a Plan.")
                    .font(PiFont.largeTitle)
                    .foregroundStyle(.white)
                    .accessibilityAddTraits(.isHeader)
                Text("Every credit to savings gets a goal before it can be spent.")
                    .font(.system(.subheadline))
                    .foregroundStyle(.white.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
                Text("Powered by Grok")
                    .font(PiFont.micro)
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.top, PiSpacing.xs)
            }
        }
    }

    private var illustration: some View {
        HStack(spacing: PiSpacing.m) {
            ForEach(["car", "cross.case", "airplane"], id: \.self) { symbol in
                Image(systemName: symbol)
                    .font(.system(size: 26))
                    .foregroundStyle(.white)
                    .frame(width: 64, height: 64)
                    .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: PiRadius.button, style: .continuous))
            }
        }
        .frame(maxWidth: .infinity, minHeight: 150)
        .background(
            StripePattern()
                .fill(.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: PiRadius.button, style: .continuous))
        )
        .accessibilityHidden(true)
    }
}

/// Diagonal stripes behind the hero illustration.
private struct StripePattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let step: CGFloat = 16
        var x = -rect.height
        while x < rect.width {
            path.move(to: CGPoint(x: x, y: rect.maxY))
            path.addLine(to: CGPoint(x: x + rect.height, y: rect.minY))
            path.addLine(to: CGPoint(x: x + rect.height + step / 2, y: rect.minY))
            path.addLine(to: CGPoint(x: x + step / 2, y: rect.maxY))
            path.closeSubpath()
            x += step
        }
        return path
    }
}

#Preview {
    PiWelcomeHero()
        .padding()
        .background(PiColor.page)
}
