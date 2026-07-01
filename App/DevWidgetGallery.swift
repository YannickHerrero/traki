#if DEBUG
import SwiftUI
import TrakiKit

/// A DEBUG-only gallery that renders the widget views at their real sizes so
/// they can be screenshot for verification (the widget gallery itself can't be
/// driven from the command line). Shown when the app is launched with
/// `-widgetGallery`.
struct DevWidgetGallery: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let palette = Palette.resolved(theme: .system, system: scheme)
        ScrollView {
            VStack(spacing: 22) {
                Text("Widget gallery")
                    .font(.barlowSemi(24, .heavy))
                    .foregroundStyle(palette.text)

                tile(width: 158, height: 158, palette: palette) {
                    TodayWidgetView(snapshot: .sample)
                }
                tile(width: 338, height: 158, palette: palette) {
                    QuickStartWidgetView()
                }
                tile(width: 338, height: 158, palette: palette) {
                    WeekWidgetView(snapshot: .sample)
                }
                tile(width: 76, height: 76, palette: palette, background: palette.text.opacity(0.12)) {
                    TodayRingView(snapshot: .sample)
                }

                Text("Live Activity")
                    .font(.barlow(12, .bold)).foregroundStyle(palette.faint)
                tile(width: 338, height: 88, palette: palette, background: Color(hex: "1E212A")) {
                    LiveActivityLockScreenView(state: sampleActivityState)
                }
            }
            .padding(24)
        }
        .background(palette.bg.ignoresSafeArea())
    }

    /// ~24:18 of Listening, matching the prototype's Live Activity mock.
    private var sampleActivityState: TrakiActivityAttributes.ContentState {
        TrakiActivityAttributes.ContentState(
            mode: .listening, isRunning: true,
            segmentStart: Date().addingTimeInterval(-1458), baseElapsed: 0)
    }

    private func tile<Content: View>(width: CGFloat, height: CGFloat, palette: Palette,
                                     background: Color? = nil,
                                     @ViewBuilder _ content: () -> Content) -> some View {
        content()
            .frame(width: width, height: height)
            .background(background ?? palette.panel)
            .clipShape(.rect(cornerRadius: width == height && width < 100 ? width / 2 : 22))
            .shadow(color: .black.opacity(0.15), radius: 10, y: 6)
            .accessibilityIdentifier("widget-tile")
    }
}
#endif
