import SwiftUI

/// Rounded square holding a line icon. Used by rows, goal cards and nav buttons.
struct PiIconTile: View {
    enum Style {
        case navyTint
        case navyFilled
        case neutral
        case locked
        case skyTint
        case surface
        case success

        var background: Color {
            switch self {
            case .navyTint: PiColor.navyTint
            case .navyFilled: PiColor.navy
            case .neutral: PiColor.field
            case .locked: PiColor.lockedFill
            case .skyTint: PiColor.skyTint
            case .surface: PiColor.surface
            case .success: PiColor.successTint
            }
        }

        var foreground: Color {
            switch self {
            case .navyTint, .surface: PiColor.navy
            case .navyFilled: .white
            case .neutral: PiColor.inkSecondary
            case .locked: PiColor.locked
            case .skyTint: PiColor.link
            case .success: PiColor.success
            }
        }
    }

    let systemName: String
    var style: Style = .navyTint
    var size: CGFloat = PiSize.iconTile
    var cornerRadius: CGFloat = PiRadius.tile

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size * 0.45, weight: .regular))
            .foregroundStyle(style.foreground)
            .frame(width: size, height: size)
            .background(style.background, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .accessibilityHidden(true)
    }
}

#Preview {
    HStack {
        PiIconTile(systemName: PiIcon.goal(named: "Car"))
        PiIconTile(systemName: PiIcon.bank, style: .navyFilled, size: PiSize.iconTileLarge)
        PiIconTile(systemName: PiIcon.lock, style: .locked)
        PiIconTile(systemName: PiIcon.check, style: .success)
    }
    .padding()
}
