import SwiftUI
import TrakiKit
import WidgetKit

/// App root: applies the user's theme, then hosts the tabbed app.
struct RootView: View {
    @Environment(AppSettings.self) private var settings
    @State private var controller = SessionController.shared
    @State private var logSheet = LogSheetController()

    var body: some View {
        TrakiThemedRoot(theme: settings.theme) {
            #if DEBUG
            if CommandLine.arguments.contains("-widgetGallery") {
                DevWidgetGallery()
            } else {
                appContent
            }
            #else
            appContent
            #endif
        }
    }

    private var appContent: some View {
        TrackingHost()
            .environment(controller)
            .environment(logSheet)
    }
}

/// Hosts the tabbed app and layers the full-screen tracking flow (Active Timer,
/// then Session Complete) above it.
private struct TrackingHost: View {
    @Environment(SessionController.self) private var controller
    @Environment(AppSettings.self) private var settings
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

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
        .onAppear {
            controller.liveActivitiesEnabled = settings.showLiveActivity
            consumePendingStart()
        }
        .onChange(of: settings.showLiveActivity) { _, enabled in
            controller.liveActivitiesEnabled = enabled
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { consumePendingStart() }
        }
    }

    /// If a widget/App-Intent quick-start is pending, drop straight into the
    /// Active Timer for that mode (without interrupting a running session).
    private func consumePendingStart() {
        guard !controller.isActive, controller.phase != .completed else { return }
        if let mode = TrakiIntentBridge.consumePendingStart() {
            controller.start(mode)
        }
    }

    /// Ends the session and writes it to the store so every derived total —
    /// Home, Stats, History, widgets — updates from the same source.
    private func stopAndSave() {
        guard let done = controller.stop(roundToMinute: settings.roundToNearestMinute) else { return }
        modelContext.insert(Session(mode: done.mode, startDate: done.startDate,
                                    durationSeconds: done.seconds, isManual: false))
        try? modelContext.save()
        WidgetCenter.shared.reloadAllTimelines()
    }
}
