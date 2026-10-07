import SwiftUI

/// `u` / `gk`: chat bubbles for the customer and Grok.
struct PiChatBubble: View {
    enum Author { case customer, grok }

    let author: Author
    let text: Text

    var body: some View {
        text
            .font(.system(.subheadline))
            .lineSpacing(2)
            .foregroundStyle(author == .customer ? .white : PiColor.ink)
            .padding(.horizontal, 15)
            .padding(.vertical, 11)
            .background(background)
            .overlay {
                if author == .grok {
                    shape.strokeBorder(PiEffect.cardHairline, lineWidth: 1)
                }
            }
            .frame(maxWidth: 300, alignment: author == .customer ? .trailing : .leading)
            .frame(maxWidth: .infinity, alignment: author == .customer ? .trailing : .leading)
            .accessibilityLabel(author == .customer ? Text("You: ") + text : Text("Grok: ") + text)
    }

    private var shape: UnevenRoundedRectangle {
        author == .customer
            ? UnevenRoundedRectangle(topLeadingRadius: 20, bottomLeadingRadius: 20, bottomTrailingRadius: 6, topTrailingRadius: 20, style: .continuous)
            : UnevenRoundedRectangle(topLeadingRadius: 20, bottomLeadingRadius: 6, bottomTrailingRadius: 20, topTrailingRadius: 20, style: .continuous)
    }

    @ViewBuilder
    private var background: some View {
        if author == .customer {
            shape.fill(PiColor.navy)
        } else {
            shape.fill(PiColor.surface)
        }
    }
}

/// `gl`: Grok explanation strip with the "Powered by Grok" mark.
struct PiGrokNote: View {
    let text: Text

    var body: some View {
        VStack(alignment: .trailing, spacing: PiSpacing.s) {
            HStack(alignment: .top, spacing: 10) {
                PiIconTile(systemName: PiIcon.sparkle, style: .surface, size: 32, cornerRadius: PiRadius.small)
                text
                    .font(.system(.subheadline))
                    .lineSpacing(3)
                    .foregroundStyle(PiColor.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Text("Powered by Grok")
                .font(PiFont.micro)
                .foregroundStyle(PiColor.grokCaption)
        }
        .padding(.horizontal, PiSpacing.l)
        .padding(.vertical, 14)
        .background(PiColor.skyTint, in: RoundedRectangle(cornerRadius: PiRadius.card, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

/// `pr`: Grok's proposal with Edit and Confirm. Changes always arrive as a card, never plain text.
struct PiProposalCard: View {
    let title: Text
    let lines: [String]
    var onEdit: (() -> Void)?
    var onConfirm: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: PiSpacing.s) {
                PiIconTile(systemName: PiIcon.sparkle, style: .skyTint, size: 28, cornerRadius: 9)
                Text("Grok's proposal")
                    .font(.system(.subheadline, weight: .bold))
                    .foregroundStyle(PiColor.navy)
            }
            .padding(.bottom, 6)
            title
                .font(.system(.subheadline, weight: .bold))
            ForEach(lines, id: \.self) { line in
                Text(verbatim: line)
                    .font(.system(.subheadline))
                    .monospacedDigit()
                    .fixedSize(horizontal: false, vertical: true)
            }
            if onEdit != nil || onConfirm != nil {
                HStack(spacing: PiSpacing.s) {
                    if let onEdit {
                        Button("Edit", action: onEdit).buttonStyle(.piCompactSecondary)
                    }
                    if let onConfirm {
                        Button("Confirm", action: onConfirm).buttonStyle(.piCompactPrimary)
                    }
                }
                .padding(.top, 10)
            }
            HStack {
                Text("Checked by PiPlanner. Estimate.")
                Spacer()
                Text("Powered by Grok")
            }
            .font(PiFont.micro)
            .foregroundStyle(PiColor.inkSecondary)
            .padding(.top, 6)
        }
        .padding(PiSpacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PiColor.surface, in: RoundedRectangle(cornerRadius: PiRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PiRadius.card, style: .continuous)
                .strokeBorder(PiColor.skyTintBorder, lineWidth: 1.5)
        }
        .shadow(color: Color(hex: 0x0078AA).opacity(0.2), radius: 12, y: 8)
    }
}

/// `chips`: suggestion chip with a sparkle.
struct PiSuggestionChip: View {
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: PiSpacing.s) {
                Image(systemName: PiIcon.sparkle)
                    .font(.system(size: 15))
                    .foregroundStyle(PiColor.link)
                    .accessibilityHidden(true)
                Text(verbatim: text)
                    .font(.system(.subheadline))
                    .foregroundStyle(PiColor.ink)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(PiColor.surface, in: RoundedRectangle(cornerRadius: PiRadius.tile, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: PiRadius.tile, style: .continuous)
                    .strokeBorder(PiEffect.cardHairline, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

/// Wrapping layout for chips.
struct PiFlowLayout: Layout {
    var spacing: CGFloat = PiSpacing.s

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        let rows = arrange(subviews: subviews, width: width)
        let height = rows.last.map { $0.y + $0.height } ?? 0
        let usedWidth = rows.map(\.width).max() ?? 0
        return CGSize(width: proposal.width ?? usedWidth, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for row in arrange(subviews: subviews, width: bounds.width) {
            for item in row.items {
                subviews[item.index].place(
                    at: CGPoint(x: bounds.minX + item.x, y: bounds.minY + row.y),
                    proposal: ProposedViewSize(width: item.size.width, height: item.size.height)
                )
            }
        }
    }

    private struct Row {
        var items: [(index: Int, x: CGFloat, size: CGSize)] = []
        var y: CGFloat = 0
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func arrange(subviews: Subviews, width: CGFloat) -> [Row] {
        var rows: [Row] = [Row()]
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(ProposedViewSize(width: width, height: nil))
            var current = rows[rows.count - 1]
            let proposedX = current.items.isEmpty ? 0 : current.width + spacing
            if proposedX + size.width > width, !current.items.isEmpty {
                let nextY = current.y + current.height + spacing
                rows.append(Row(y: nextY))
                current = rows[rows.count - 1]
            }
            let x = current.items.isEmpty ? 0 : current.width + spacing
            current.items.append((index, x, size))
            current.width = x + size.width
            current.height = max(current.height, size.height)
            rows[rows.count - 1] = current
        }
        return rows.filter { !$0.items.isEmpty }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: PiSpacing.m) {
            PiChatBubble(author: .customer, text: Text("Move 5k from Emergency to Car"))
            PiChatBubble(author: .grok, text: Text("What is the target amount, and by when?"))
            PiProposalCard(title: Text("Move ₹5,000 from Emergency to Car"), lines: ["Emergency keeps ₹50,000 · Car reaches ₹90,000"], onEdit: {}, onConfirm: {})
            PiGrokNote(text: Text("₹1,00,000 was already assigned. This ₹50,000 is new."))
            PiFlowLayout {
                PiSuggestionChip(text: "What happens if I change the split?") {}
                PiSuggestionChip(text: "How are my goals doing?") {}
            }
        }
        .padding()
    }
    .background(PiColor.page)
}
