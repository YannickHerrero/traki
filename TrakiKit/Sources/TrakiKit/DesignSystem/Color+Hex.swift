import SwiftUI

public extension Color {
    /// Creates an opaque color from a 6-digit hex string such as `"#F6A93B"`
    /// (a leading `#` is optional). Used throughout the design system so tokens
    /// can be written exactly as they appear in the original prototype.
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        let r = Double((value >> 16) & 0xFF) / 255
        let g = Double((value >> 8) & 0xFF) / 255
        let b = Double(value & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}
