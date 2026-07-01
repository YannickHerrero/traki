import SwiftUI
import TrakiKit

/// The launchpad — greeting, streak, goal, resume hero, mode cards, log-past.
/// Built out in Phase 3.
struct HomeScreen: View {
    @Environment(\.palette) private var palette

    var body: some View {
        VStack {
            Text("Home")
                .font(.nunito(26, .heavy))
                .foregroundStyle(palette.text)
        }
    }
}
