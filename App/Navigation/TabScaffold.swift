import SwiftUI
import TrakiKit

/// Hosts the selected tab's screen over the themed background, with the tab bar
/// pinned to the bottom as a safe-area inset (content scrolls above it).
struct TabScaffold: View {
    @Environment(\.palette) private var palette
    @Environment(LogSheetController.self) private var logSheet
    @State private var tab: AppTab = .home

    var body: some View {
        @Bindable var logSheet = logSheet
        ZStack {
            palette.bg.ignoresSafeArea()

            Group {
                switch tab {
                case .home: HomeScreen()
                case .stats: StatsScreen()
                case .history: HistoryScreen()
                case .settings: SettingsScreen()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            TrakiTabBar(selection: $tab)
        }
        .sheet(isPresented: $logSheet.isPresented) {
            LogSheetView(controller: logSheet)
        }
    }
}
