import SwiftUI
import TrakiKit

/// App root: applies the user's theme, then hosts the tabbed app.
struct RootView: View {
    @Environment(AppSettings.self) private var settings
    @State private var controller = SessionController()

    var body: some View {
        TrakiThemedRoot(theme: settings.theme) {
            TrackingHost()
                .environment(controller)
        }
    }
}

/// Hosts the tabbed app and layers the full-screen tracking flow (Active Timer,
/// then Session Complete) above it.
private struct TrackingHost: View {
    @Environment(SessionController.self) private var controller

    var body: some View {
        ZStack {
            TabScaffold()

            if controller.isActive {
                ActiveTimerView(onStop: { controller.stop() })
                    .transition(.move(edge: .bottom))
                    .zIndex(1)
            }
        }
        .animation(.snappy(duration: 0.3), value: controller.isActive)
    }
}
