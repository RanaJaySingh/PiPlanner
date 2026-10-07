import SwiftUI

// MARK: - Colors

/// Colour tokens read from the scenario mockups (docs/design/PiPlanner-Scenario-Mockups.dc.html).
enum PiColor {
    static let navy = Color(hex: 0x002E6E)
    static let sky = Color(hex: 0x00B9F1)
    static let skyDeep = Color(hex: 0x0096D6)
    static let link = Color(hex: 0x00658F)
    static let skyHighlight = Color(hex: 0x7FD8F7)

    static let ink = Color(hex: 0x101010)
    static let inkStrong = Color(hex: 0x2B3443)
    static let inkMuted = Color(hex: 0x4A5466)
    static let inkSecondary = Color(hex: 0x6B7280)
    static let inkPlaceholder = Color(hex: 0x8A94A6)
    static let chevron = Color(hex: 0x9AA4B2)

    static let page = Color(hex: 0xF4F6FA)
    static let surface = Color.white
    static let field = Color(hex: 0xF3F6FA)
    static let fieldSubtle = Color(hex: 0xF7F9FC)
    static let hairline = Color(hex: 0xEEF1F5)
    static let divider = Color(hex: 0xE3E7ED)
    static let dragIndicator = Color(hex: 0xDDE3EB)

    static let navyTint = Color(hex: 0xEAF1FB)
    static let skyTint = Color(hex: 0xE3F4FD)
    static let skyTintBorder = Color(hex: 0xBFE7F8)
    static let assignPill = Color(hex: 0xBFEBFB)
    static let pendingText = Color(hex: 0x00527A)
    static let grokCaption = Color(hex: 0x5B7287)

    static let lockedFill = Color(hex: 0xEEF1F6)
    static let locked = Color(hex: 0x7A8698)
    static let lockedTitle = Color(hex: 0x6B7A8C)

    static let success = Color(hex: 0x0A8F5B)
    static let successTint = Color(hex: 0xE3F3EC)
    static let warning = Color(hex: 0xB26A00)
    static let warningTint = Color(hex: 0xFBF3E4)
    static let warningText = Color(hex: 0x7A4A00)
    static let demoTag = Color(hex: 0x8A5300)
    static let danger = Color(hex: 0xC62828)
    static let dangerTint = Color(hex: 0xFDEDED)

    static let toggleOff = Color(hex: 0xD5DAE1)
    static let progressTrack = Color(hex: 0xEDF1F6)
    static let toast = Color(hex: 0x0F1A2B)
}

// MARK: - Shape and spacing

enum PiRadius {
    static let small: CGFloat = 10
    static let field: CGFloat = 12
    static let tile: CGFloat = 14
    static let iconLarge: CGFloat = 15
    static let pinKey: CGFloat = 16
    static let button: CGFloat = 18
    static let row: CGFloat = 20
    static let card: CGFloat = 24
    static let hero: CGFloat = 28
}

enum PiSpacing {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 12
    static let l: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    /// Horizontal margin of every screen in the mockups.
    static let screen: CGFloat = 12
}

enum PiSize {
    static let buttonHeight: CGFloat = 56
    static let compactButtonHeight: CGFloat = 46
    static let navButton: CGFloat = 40
    static let iconTile: CGFloat = 40
    static let iconTileLarge: CGFloat = 48
    static let minimumTapTarget: CGFloat = 44
}

// MARK: - Typography

/// Text styles mapped from the mockup sizes onto Dynamic Type styles so copy scales.
enum PiFont {
    static let balance = Font.system(.largeTitle, weight: .bold).monospacedDigit()
    static let amountEntry = Font.system(size: 48, weight: .bold).monospacedDigit()
    static let amountHeadline = Font.system(.title, weight: .bold).monospacedDigit()
    static let largeTitle = Font.system(.title, weight: .bold)
    static let sheetTitle = Font.system(.title3, weight: .bold)
    static let heading = Font.system(.headline, weight: .bold)
    static let section = Font.system(.headline, weight: .bold)
    static let navTitle = Font.system(.headline, weight: .semibold)
    static let button = Font.system(.headline, weight: .semibold)
    static let body = Font.system(.subheadline)
    static let bodyEmphasis = Font.system(.subheadline, weight: .semibold)
    static let rowTitle = Font.system(.callout, weight: .semibold)
    static let caption = Font.system(.footnote)
    static let captionEmphasis = Font.system(.footnote, weight: .semibold)
    static let tag = Font.system(.caption, weight: .bold)
    static let micro = Font.system(.caption2)
    static let microEmphasis = Font.system(.caption2, weight: .semibold)
}

// MARK: - Effects

enum PiEffect {
    /// `SHV` in the mockups: a 1 pt navy hairline plus a soft drop.
    static let cardShadowColor = Color(hex: 0x101828).opacity(0.04)
    static let cardHairline = PiColor.navy.opacity(0.05)

    /// `HEROBG` in the mockups.
    static var heroBackground: some View {
        ZStack {
            PiColor.navy
            RadialGradient(
                colors: [PiColor.sky.opacity(0.30), PiColor.sky.opacity(0)],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 260
            )
        }
    }

    static let progressGradient = LinearGradient(
        colors: [PiColor.sky, PiColor.skyDeep],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let disabledOpacity: Double = 0.4
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}
