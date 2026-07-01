import SwiftUI
import TrakiKit

/// App root: applies the user's theme, then hosts the tabbed app.
struct RootView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        TrakiThemedRoot(theme: settings.theme) {
            TabScaffold()
        }
    }
}
