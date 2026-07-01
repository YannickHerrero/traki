import SwiftUI
import WidgetKit

/// Entry point for Traki's widgets and Live Activity. Individual widgets are
/// added to `body` across the coming commits.
@main
struct TrakiWidgetBundle: WidgetBundle {
    var body: some Widget {
        TodayWidget()
        QuickStartWidget()
    }
}
