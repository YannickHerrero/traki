import SwiftUI
import TrakiKit
import WidgetKit

/// Home Screen · small · today — today's total, streak and goal progress.
struct TodayWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TodayWidget", provider: SnapshotProvider()) { entry in
            TodayWidgetView(snapshot: entry.snapshot)
        }
        .configurationDisplayName("Today")
        .description("Today's study time, streak and goal.")
        .supportedFamilies([.systemSmall])
    }
}

struct TodayWidgetView: View {
    @Environment(\.colorScheme) private var scheme
    let snapshot: TrakiSnapshot

    var body: some View {
        let palette = Palette.resolved(theme: .system, system: scheme)
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(LearningMode.flashcards.baseColor)
                    .frame(width: 8, height: 8)
                    .rotationEffect(.degrees(45))
                Text("\(snapshot.streak)")
                    .font(.nunito(13, .heavy))
                    .foregroundStyle(LearningMode.flashcards.ink(dark: palette.isDark))
                Text("day streak")
                    .font(.nunito(11, .bold))
                    .foregroundStyle(palette.faint)
            }

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 6) {
                Text(TrakiFormat.duration(snapshot.todaySeconds))
                    .font(.nunito(34, .heavy))
                    .foregroundStyle(palette.text)
                    .lineLimit(1).minimumScaleFactor(0.7)
                Text("studied today · \(snapshot.goalPercent)%")
                    .font(.nunito(12, .bold))
                    .foregroundStyle(palette.faint)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(palette.track)
                        Capsule()
                            .fill(LinearGradient(colors: [LearningMode.sentenceMining.baseColor,
                                                          LearningMode.reading.baseColor],
                                                 startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * CGFloat(snapshot.goalPercent) / 100)
                    }
                }
                .frame(height: 6)
            }
        }
        .containerBackground(palette.panel, for: .widget)
    }
}

#Preview(as: .systemSmall) {
    TodayWidget()
} timeline: {
    SnapshotEntry(date: .now, snapshot: .sample)
}
