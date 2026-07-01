import SwiftUI

/// Bundled type ramp. Sizes are given in points and scale with Dynamic Type via
/// `relativeTo:`. Weights map to the nearest bundled face (unavailable weights
/// clamp to the closest one) so call sites read naturally, e.g.
/// `.nunito(26, .heavy)` or `.barlowSemi(52, .heavy, relativeTo: .largeTitle)`.
public extension Font {

    /// Nunito — the Playful Cards home, chips, and small widgets. Faces: 600/700/800/900.
    static func nunito(_ size: CGFloat, _ weight: Font.Weight = .black,
                       relativeTo style: Font.TextStyle = .body) -> Font {
        TrakiFonts.register()
        let face: String
        switch weight {
        case .thin, .ultraLight, .light, .regular, .medium, .semibold: face = "Nunito-SemiBold"
        case .bold: face = "Nunito-Bold"
        case .heavy: face = "Nunito-ExtraBold"
        default: face = "Nunito-Black" // .black and anything heavier
        }
        return .custom(face, size: size, relativeTo: style)
    }

    /// Barlow — body copy, buttons, section labels. Faces: 400/500/600/700/800.
    static func barlow(_ size: CGFloat, _ weight: Font.Weight = .regular,
                       relativeTo style: Font.TextStyle = .body) -> Font {
        TrakiFonts.register()
        let face: String
        switch weight {
        case .thin, .ultraLight, .light, .regular: face = "Barlow-Regular"
        case .medium: face = "Barlow-Medium"
        case .semibold: face = "Barlow-SemiBold"
        case .bold: face = "Barlow-Bold"
        default: face = "Barlow-ExtraBold" // .heavy / .black
        }
        return .custom(face, size: size, relativeTo: style)
    }

    /// Barlow Semi Condensed — screen titles, the big clock, stat totals, session
    /// durations. Faces: 500/600/700/800.
    static func barlowSemi(_ size: CGFloat, _ weight: Font.Weight = .bold,
                           relativeTo style: Font.TextStyle = .body) -> Font {
        TrakiFonts.register()
        let face: String
        switch weight {
        case .thin, .ultraLight, .light, .regular, .medium: face = "BarlowSemiCondensed-Medium"
        case .semibold: face = "BarlowSemiCondensed-SemiBold"
        case .bold: face = "BarlowSemiCondensed-Bold"
        default: face = "BarlowSemiCondensed-ExtraBold" // .heavy / .black
        }
        return .custom(face, size: size, relativeTo: style)
    }
}
