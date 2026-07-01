import SwiftUI
import TrakiKit

/// App root: applies the user's theme, then hosts the main content. The tab
/// scaffold replaces the placeholder in the next commit.
struct RootView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        TrakiThemedRoot(theme: settings.theme) {
            ThemedPlaceholder()
        }
    }
}

/// Temporary themed splash — confirms `\.palette` resolves for Light/Dark/System.
private struct ThemedPlaceholder: View {
    @Environment(\.palette) private var palette

    var body: some View {
        ZStack {
            palette.bg.ignoresSafeArea()
            VStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(LinearGradient(colors: [LearningMode.flashcards.baseColor,
                                                  LearningMode.sentenceMining.baseColor],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 48, height: 48)
                Text("Traki")
                    .font(.barlowSemi(34, .heavy, relativeTo: .largeTitle))
                    .foregroundStyle(palette.text)
                Text("Time tracker for language learners")
                    .font(.barlow(15, .medium))
                    .foregroundStyle(palette.muted)
            }
        }
    }
}
