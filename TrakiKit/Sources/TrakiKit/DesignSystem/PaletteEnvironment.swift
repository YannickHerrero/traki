import SwiftUI

public extension EnvironmentValues {
    /// The resolved neutral tokens for the current appearance. Read with
    /// `@Environment(\.palette)`; injected near the app root by the theme wrapper.
    @Entry var palette: Palette = .light
}
