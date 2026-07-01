import SwiftUI
import TrakiKit
import WidgetKit

// Placeholder implementation; the shared timeline provider and real layout land
// in the next commits.

struct TodayEntry: TimelineEntry {
    let date: Date
}

struct TodayProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodayEntry { TodayEntry(date: Date()) }
    func getSnapshot(in context: Context, completion: @escaping (TodayEntry) -> Void) {
        completion(TodayEntry(date: Date()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayEntry>) -> Void) {
        completion(Timeline(entries: [TodayEntry(date: Date())], policy: .never))
    }
}

struct TodayWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TodayWidget", provider: TodayProvider()) { _ in
            Text("Traki")
                .font(.nunito(20, .heavy))
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Today")
        .description("Today's study time, streak and goal.")
        .supportedFamilies([.systemSmall])
    }
}
