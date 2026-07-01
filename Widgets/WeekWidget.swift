import SwiftUI
import TrakiKit
import WidgetKit

/// Home Screen · medium · this week — the weekly heatmap and total, for a
/// motivating glance.
struct WeekWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "WeekWidget", provider: SnapshotProvider()) { entry in
            WeekWidgetView(snapshot: entry.snapshot)
        }
        .configurationDisplayName("This week")
        .description("Your weekly consistency and total.")
        .supportedFamilies([.systemMedium])
    }
}

struct WeekWidgetView: View {
    @Environment(\.colorScheme) private var scheme
    let snapshot: TrakiSnapshot

    var body: some View {
        let palette = Palette.resolved(theme: .system, system: scheme)
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("This week")
                    .font(.barlow(13, .bold))
                    .foregroundStyle(palette.muted)
                Spacer()
                Text(TrakiFormat.duration(snapshot.weekTotalSeconds))
                    .font(.barlowSemi(16, .heavy)).monospacedDigit()
                    .foregroundStyle(LearningMode.reading.baseColor)
            }

            // 7 rows × 7 columns, column-major (one column per week).
            Grid(horizontalSpacing: 3, verticalSpacing: 3) {
                ForEach(0..<7, id: \.self) { row in
                    GridRow {
                        ForEach(Array(stride(from: row, to: snapshot.weekHeatLevels.count, by: 7)),
                                id: \.self) { index in
                            RoundedRectangle(cornerRadius: 2.5)
                                .fill(heatColor(snapshot.weekHeatLevels[index], palette))
                                .aspectRatio(1, contentMode: .fit)
                        }
                    }
                }
            }
        }
        .containerBackground(palette.panel, for: .widget)
    }

    private func heatColor(_ level: Int, _ palette: Palette) -> Color {
        let green = LearningMode.reading.baseColor
        switch level {
        case 0: return palette.track
        case 1: return green.opacity(0.35)
        case 2: return green.opacity(0.55)
        case 3: return green.opacity(0.75)
        default: return green.opacity(0.95)
        }
    }
}

#Preview(as: .systemMedium) {
    WeekWidget()
} timeline: {
    SnapshotEntry(date: .now, snapshot: .sample)
}
