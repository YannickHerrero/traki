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
    @Environment(AppSettings.self) private var settings
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            TabScaffold()

            if controller.isActive {
                ActiveTimerView(onStop: stopAndSave)
                    .transition(.move(edge: .bottom))
                    .zIndex(1)
            }

            if controller.phase == .completed {
                SessionCompleteView(
                    onAgain: { if let mode = controller.completed?.mode { controller.start(mode) } },
                    onDone: { controller.clear() })
                    .transition(.opacity)
                    .zIndex(2)
            }
        }
        .animation(.snappy(duration: 0.3), value: controller.phase)
    }

    /// Ends the session and writes it to the store so every derived total —
    /// Home, Stats, History, widgets — updates from the same source.
    private func stopAndSave() {
        guard let done = controller.stop(roundToMinute: settings.roundToNearestMinute) else { return }
        modelContext.insert(Session(mode: done.mode, startDate: done.startDate,
                                    durationSeconds: done.seconds, isManual: false))
        try? modelContext.save()
    }
}
