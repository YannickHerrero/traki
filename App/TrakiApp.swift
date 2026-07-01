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
        let container = TrakiStore.makeContainer()
        self.container = container
        _settings = State(initialValue: AppSettings())
        #if DEBUG
        SampleData.seedIfEmpty(container.mainContext)
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
