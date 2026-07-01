import SwiftUI
import TrakiKit

/// Hosts the selected tab's screen over the themed background, with the tab bar
/// pinned to the bottom as a safe-area inset (content scrolls above it).
struct TabScaffold: View {
    @Environment(\.palette) private var palette
    @State private var tab: AppTab = .home

    var body: some View {
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
    }
}
