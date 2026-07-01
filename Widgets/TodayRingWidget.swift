import SwiftUI
import TrakiKit
import WidgetKit

/// Lock Screen · circular — a compact today-total ring showing progress toward
/// the daily goal. (Per-mode quick-start from the Lock Screen is added with the
/// App Intent in Phase 10.)
struct TodayRingWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TodayRingWidget", provider: SnapshotProvider()) { entry in
            TodayRingView(snapshot: entry.snapshot)
        }
        .configurationDisplayName("Today ring")
        .description("Today's progress toward your goal.")
        .supportedFamilies([.accessoryCircular])
    }
}

struct TodayRingView: View {
    let snapshot: TrakiSnapshot

    var body: some View {
        Gauge(value: Double(snapshot.goalPercent), in: 0...100) {
            Image(systemName: "book.fill")
        } currentValueLabel: {
            Text(compactToday)
                .font(.nunito(13, .heavy))
                .minimumScaleFactor(0.6)
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .containerBackground(.clear, for: .widget)
    }

    /// Tight form for the ring centre, e.g. "1h42" or "42m".
    private var compactToday: String {
        let seconds = snapshot.todaySeconds
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        return hours > 0 ? "\(hours)h\(String(format: "%02d", minutes))" : "\(minutes)m"
    }
}

#Preview(as: .accessoryCircular) {
    TodayRingWidget()
} timeline: {
    SnapshotEntry(date: .now, snapshot: .sample)
}
