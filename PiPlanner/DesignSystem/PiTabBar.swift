import SwiftUI

/// `tabs`: Goals / History / Ask bar with a tinted pill behind the active icon.
struct PiTabBar<Tab: Hashable>: View {
    struct Item: Identifiable {
        let tab: Tab
        let title: LocalizedStringKey
        let icon: String
        var id: Tab { tab }
    }

    let items: [Item]
    @Binding var selection: Tab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items) { item in
                let isSelected = item.tab == selection
                Button {
                    selection = item.tab
                } label: {
                    VStack(spacing: PiSpacing.xs) {
                        Image(systemName: item.icon)
                            .font(.system(size: 19))
                            .frame(width: 56, height: 32)
                            .background(isSelected ? PiColor.navyTint : .clear, in: RoundedRectangle(cornerRadius: PiRadius.field, style: .continuous))
                        Text(item.title)
                            .font(PiFont.microEmphasis)
                    }
                    .foregroundStyle(isSelected ? PiColor.navy : PiColor.inkPlaceholder)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
                .accessibilityIdentifier("tab.\(item.tab)")
            }
        }
        .padding(.horizontal, PiSpacing.l)
        .padding(.top, PiSpacing.s)
        .background {
            PiColor.surface
                .shadow(color: PiColor.navy.opacity(0.06), radius: 0, y: -1)
                .ignoresSafeArea(edges: .bottom)
        }
    }
}

#Preview {
    @Previewable @State var selection = 0
    VStack {
        Spacer()
        PiTabBar(items: [
            .init(tab: 0, title: "Goals", icon: PiIcon.goals),
            .init(tab: 1, title: "History", icon: PiIcon.history),
            .init(tab: 2, title: "Ask", icon: PiIcon.ask),
        ], selection: $selection)
    }
    .background(PiColor.page)
}
