import SwiftUI

/// The user's appearance choice. `System` follows the phone's own light/dark
/// setting; the default is `System`. Raw values match the prototype so they
/// persist unchanged.
public enum AppTheme: String, CaseIterable, Identifiable, Codable, Sendable {
    case light = "Light"
    case dark = "Dark"
    case system = "System"

    public var id: String { rawValue }

    public var label: String { rawValue }

    /// Resolves to a concrete appearance given the current system color scheme.
    public func isDark(system: ColorScheme) -> Bool {
        switch self {
        case .light: false
        case .dark: true
        case .system: system == .dark
        }
    }

    /// Drives `.preferredColorScheme`; `nil` lets the system decide.
    public var preferredColorScheme: ColorScheme? {
        switch self {
        case .light: .light
        case .dark: .dark
        case .system: nil
        }
    }
}
