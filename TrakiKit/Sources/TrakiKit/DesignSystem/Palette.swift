import SwiftUI

/// The neutral color tokens for one appearance, mirroring the prototype's
/// `palette()`. Mode colors live on ``LearningMode``; everything else — surfaces,
/// text tints, hairlines — comes from here so light and dark stay consistent.
public struct Palette: Sendable {
    public let isDark: Bool

    public let bg: Color          // screen background
    public let panel: Color       // cards / grouped rows
    public let panel2: Color      // raised panel
    public let text: Color        // primary ink
    public let muted: Color       // secondary text
    public let faint: Color       // tertiary text / captions
    public let dim: Color         // most subdued (home indicator, idle tab)
    public let track: Color       // progress/segment tracks
    public let hair: Color        // hairline separators
    public let chip: Color        // subtle chip fill
    public let tabbar: Color      // translucent tab bar fill

    /// Soft drop shadow for cards in light mode; absent in dark mode.
    public let panelShadow: ShadowStyle

    public struct ShadowStyle: Sendable {
        public let color: Color
        public let radius: CGFloat
        public let y: CGFloat
        public static let none = ShadowStyle(color: .clear, radius: 0, y: 0)
    }

    // Dark: ink is #F4F5F7; track/hair/chip use pure white. tabbar = bg @ .82.
    public static let dark = Palette(
        isDark: true,
        bg: Color(hex: "0E0F13"),
        panel: Color(hex: "16181E"),
        panel2: Color(hex: "1E212A"),
        text: Color(hex: "F4F5F7"),
        muted: Color(hex: "F4F5F7").opacity(0.60),
        faint: Color(hex: "F4F5F7").opacity(0.45),
        dim: Color(hex: "F4F5F7").opacity(0.32),
        track: Color.white.opacity(0.08),
        hair: Color.white.opacity(0.06),
        chip: Color.white.opacity(0.05),
        tabbar: Color(hex: "0E0F13").opacity(0.82),
        panelShadow: .none
    )

    // Light: ink is #1E1B29; tabbar = white @ .90; cards get a soft shadow.
    public static let light = Palette(
        isDark: false,
        bg: Color(hex: "F4F2F9"),
        panel: Color(hex: "FFFFFF"),
        panel2: Color(hex: "FFFFFF"),
        text: Color(hex: "1E1B29"),
        muted: Color(hex: "1E1B29").opacity(0.62),
        faint: Color(hex: "1E1B29").opacity(0.46),
        dim: Color(hex: "1E1B29").opacity(0.34),
        track: Color(hex: "1E1B29").opacity(0.08),
        hair: Color(hex: "1E1B29").opacity(0.07),
        chip: Color(hex: "1E1B29").opacity(0.04),
        tabbar: Color.white.opacity(0.90),
        panelShadow: ShadowStyle(color: Color(hex: "1E1B29").opacity(0.06), radius: 7, y: 4)
    )

    /// Resolves the palette for a theme against the system appearance.
    public static func resolved(theme: AppTheme, system: ColorScheme) -> Palette {
        theme.isDark(system: system) ? .dark : .light
    }
}
