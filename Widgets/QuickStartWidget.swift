import SwiftUI
import TrakiKit
import WidgetKit

/// Home Screen · medium · quick start — all four modes as buttons; one tap
/// begins a session. (The tap is wired to an App Intent in Phase 10.)
struct QuickStartWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "QuickStartWidget", provider: SnapshotProvider()) { _ in
            QuickStartWidgetView()
        }
        .configurationDisplayName("Quick start")
        .description("Start a session in one tap.")
        .supportedFamilies([.systemMedium])
    }
}

struct QuickStartWidgetView: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let palette = Palette.resolved(theme: .system, system: scheme)
        VStack(alignment: .leading, spacing: 11) {
            Text("START A SESSION")
                .font(.nunito(11, .heavy)).tracking(0.6)
                .foregroundStyle(palette.faint)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 9),
                                GridItem(.flexible(), spacing: 9)], spacing: 9) {
                ForEach(LearningMode.allCases) { mode in
                    chip(mode, palette: palette)
                }
            }
        }
        .containerBackground(palette.panel, for: .widget)
    }

    private func chip(_ mode: LearningMode, palette: Palette) -> some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 3)
                .fill(mode.baseColor)
                .frame(width: 9, height: 9)
            Text(mode.compactName)
                .font(.nunito(12.5, .heavy))
                .foregroundStyle(mode.ink(dark: palette.isDark))
            Spacer(minLength: 0)
        }
        .padding(11)
        .background(mode.baseColor.opacity(0.16), in: .rect(cornerRadius: 14, style: .continuous))
    }
}

#Preview(as: .systemMedium) {
    QuickStartWidget()
} timeline: {
    SnapshotEntry(date: .now, snapshot: .sample)
}
