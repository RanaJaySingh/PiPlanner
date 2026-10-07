import SwiftUI

/// `hdr`: Paytm-style top bar with the avatar initial and notifications.
struct PiAppHeader: View {
    let initial: String

    var body: some View {
        HStack(spacing: 10) {
            Text(verbatim: initial)
                .font(.system(.headline, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(PiColor.navy, in: RoundedRectangle(cornerRadius: PiRadius.tile, style: .continuous))
                .accessibilityHidden(true)
            HStack(spacing: PiSpacing.s) {
                Image(systemName: PiIcon.search)
                Text("Search")
                Spacer(minLength: 0)
            }
            .font(.system(.subheadline))
            .foregroundStyle(PiColor.inkPlaceholder)
            .padding(.horizontal, 14)
            .frame(height: 40)
            .background(PiColor.surface, in: RoundedRectangle(cornerRadius: PiRadius.tile, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: PiRadius.tile, style: .continuous)
                    .strokeBorder(PiEffect.cardHairline, lineWidth: 1)
            }
            .accessibilityHidden(true)
            Image(systemName: PiIcon.notifications)
                .font(.system(size: 18))
                .foregroundStyle(PiColor.navy)
                .frame(width: 40, height: 40)
                .background(PiColor.surface, in: RoundedRectangle(cornerRadius: PiRadius.tile, style: .continuous))
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(PiColor.sky)
                        .frame(width: 7, height: 7)
                        .overlay(Circle().stroke(.white, lineWidth: 1.5))
                        .padding(9)
                }
                .accessibilityHidden(true)
        }
        .padding(.top, 6)
        .padding(.bottom, PiSpacing.xxs)
    }
}

/// `gr`: greeting line inside the hero with insight and settings buttons.
struct PiGreetingRow: View {
    let greeting: Text
    let onInsights: () -> Void
    let onSettings: () -> Void

    var body: some View {
        HStack {
            greeting
                .font(.system(.subheadline, weight: .semibold))
                .foregroundStyle(.white)
            Spacer()
            HStack(spacing: PiSpacing.s) {
                heroButton(PiIcon.insights, label: "History", action: onInsights)
                heroButton(PiIcon.settings, label: "Settings", action: onSettings)
            }
        }
    }

    private func heroButton(_ icon: String, label: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 17))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: PiRadius.field, style: .continuous))
                .frame(minWidth: PiSize.minimumTapTarget, minHeight: PiSize.minimumTapTarget)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

/// One of the four `tiles` in the hero.
struct PiQuickTile: View {
    let icon: String
    let title: Text
    let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            VStack(spacing: PiSpacing.s) {
                Image(systemName: icon)
                    .font(.system(size: 21))
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
                    .background(.white.opacity(0.13), in: RoundedRectangle(cornerRadius: PiRadius.pinKey, style: .continuous))
                title
                    .font(PiFont.micro)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1 : 0.35)
    }
}

#Preview {
    VStack {
        PiAppHeader(initial: "R")
        PiCard(style: .hero) {
            PiGreetingRow(greeting: Text("Good evening, Rahul"), onInsights: {}, onSettings: {})
            HStack {
                PiQuickTile(icon: PiIcon.sync, title: Text("Sync")) {}.disabled(true)
                PiQuickTile(icon: PiIcon.add, title: Text("New goal")) {}
                PiQuickTile(icon: PiIcon.transfer, title: Text("Transfer")) {}
                PiQuickTile(icon: PiIcon.history, title: Text("History")) {}
            }
        }
    }
    .padding()
    .background(PiColor.page)
}
