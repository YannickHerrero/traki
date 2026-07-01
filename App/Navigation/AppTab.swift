import Foundation

/// The four everyday destinations anchored by the bottom tab bar.
enum AppTab: String, CaseIterable, Identifiable {
    case home, stats, history, settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: "Home"
        case .stats: "Stats"
        case .history: "History"
        case .settings: "Settings"
        }
    }

    var symbol: String {
        switch self {
        case .home: "house.fill"
        case .stats: "chart.bar.fill"
        case .history: "clock"
        case .settings: "slider.horizontal.3"
        }
    }
}
