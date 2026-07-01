import SwiftUI
import TrakiKit

/// Settings — Learning, Appearance, Tracking. Built out in Phase 8.
struct SettingsScreen: View {
    @Environment(\.palette) private var palette

    var body: some View {
        VStack {
            Text("Settings")
                .font(.barlowSemi(30, .heavy))
                .foregroundStyle(palette.text)
        }
    }
}
