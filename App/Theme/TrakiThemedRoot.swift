import SwiftUI
import TrakiKit

/// Applies the user's theme at the app root: forces the color scheme (or follows
/// the system for `.system`) and injects the matching ``Palette`` so every
/// descendant reads tokens from `\.palette`.
struct TrakiThemedRoot<Content: View>: View {
    let theme: AppTheme
    @ViewBuilder let content: Content

    var body: some View {
        Resolver(theme: theme) { content }
            .preferredColorScheme(theme.preferredColorScheme)
    }

    /// Reads the (now-forced) color scheme and resolves the palette from it.
    private struct Resolver<C: View>: View {
        let theme: AppTheme
        @ViewBuilder let content: C
        @Environment(\.colorScheme) private var colorScheme

        var body: some View {
            let palette = Palette.resolved(theme: theme, system: colorScheme)
            content
                .environment(\.palette, palette)
                .tint(palette.text)
        }
    }
}
