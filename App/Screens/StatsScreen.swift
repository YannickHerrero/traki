import SwiftUI
import TrakiKit

/// Statistics — period switch, 7-day bars, breakdown, trend, heatmap.
/// Built out in Phase 7.
struct StatsScreen: View {
    @Environment(\.palette) private var palette

    var body: some View {
        VStack {
            Text("Statistics")
                .font(.barlowSemi(30, .heavy))
                .foregroundStyle(palette.text)
        }
    }
}
