import SwiftUI
import TrakiKit

/// App root: applies the user's theme, then hosts the tabbed app.
struct RootView: View {
    @Environment(AppSettings.self) private var settings
    @State private var controller = SessionController()

    var body: some View {
        TrakiThemedRoot(theme: settings.theme) {
            TabScaffold()
                .environment(controller)
        }
    }
}
