import SwiftUI
import TrakiKit

/// History — every session grouped by day, hold-to-edit. Built out in Phase 6.
struct HistoryScreen: View {
    @Environment(\.palette) private var palette

    var body: some View {
        VStack {
            Text("History")
                .font(.barlowSemi(30, .heavy))
                .foregroundStyle(palette.text)
        }
    }
}
