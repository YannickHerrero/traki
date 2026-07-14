import SwiftData
import SwiftUI
import TrakiKit

@main
struct TrakiApp: App {
    @State private var settings: AppSettings
    private let container: ModelContainer

    @MainActor
    init() {
        TrakiFonts.register()
        let container = TrakiStore.makeContainer(cloudSync: true)
        self.container = container
        TrakiStore.migrateLocalStoreIfNeeded(into: container)
        _settings = State(initialValue: AppSettings())
        #if DEBUG
        SampleData.seedIfEmpty(container.mainContext)
        // Simulate a widget/App-Intent quick-start for UI testing:
        // `-simulateIntentStart <modeRawValue>`.
        let arguments = CommandLine.arguments
        if let index = arguments.firstIndex(of: "-simulateIntentStart"),
           index + 1 < arguments.count,
           let mode = LearningMode(rawValue: arguments[index + 1]) {
            TrakiIntentBridge.requestStart(mode)
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(settings)
        }
        .modelContainer(container)
    }
}
