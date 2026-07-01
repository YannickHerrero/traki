import Foundation
import SwiftData
import TrakiKit
import WidgetKit

/// The values Traki's widgets display, computed once from the shared store so
/// every widget family renders from the same source.
struct TrakiSnapshot: Sendable {
    let todaySeconds: Int
    let streak: Int
    let goalMinutes: Int
    let todayByMode: [LearningMode: Int]
    let weekTotalSeconds: Int
    let weekHeatLevels: [Int]   // last 49 days, oldest-first (7×7 mini heatmap)

    var goalPercent: Int {
        guard goalMinutes > 0 else { return 0 }
        return min(100, Int((Double(todaySeconds) / Double(goalMinutes * 60) * 100).rounded()))
    }

    static func build(from aggregator: SessionAggregator, goalMinutes: Int) -> TrakiSnapshot {
        let today = aggregator.totalsByMode(onDayStarting:
            aggregator.calendar.startOfDay(for: aggregator.now))
        let week = aggregator.lastDays(7).reduce(0) { $0 + $1.total }
        return TrakiSnapshot(
            todaySeconds: aggregator.todaySeconds,
            streak: aggregator.currentStreak(),
            goalMinutes: goalMinutes,
            todayByMode: today,
            weekTotalSeconds: week,
            weekHeatLevels: aggregator.heatmap(days: 49).map(\.level))
    }

    /// Deterministic sample for placeholders and previews (no store access).
    static var sample: TrakiSnapshot {
        let now = Date()
        let aggregator = SessionAggregator(sessions: SampleData.snapshots(now: now), now: now)
        return build(from: aggregator, goalMinutes: 120)
    }
}

/// Loads a snapshot from the shared App-Group SwiftData store plus the shared
/// settings defaults.
enum TrakiWidgetData {
    static func load(now: Date = Date()) -> TrakiSnapshot {
        let container = TrakiStore.makeContainer()
        let context = ModelContext(container)
        let sessions = (try? context.fetch(FetchDescriptor<Session>())) ?? []
        let aggregator = SessionAggregator(sessions: sessions.map(\.snapshot), now: now)

        let defaults = UserDefaults(suiteName: TrakiStore.appGroupID)
        let goal = defaults?.object(forKey: "settings.dailyGoalMinutes") as? Int ?? 120

        return TrakiSnapshot.build(from: aggregator, goalMinutes: goal)
    }
}

/// One timeline entry carrying a freshly-loaded snapshot.
struct SnapshotEntry: TimelineEntry {
    let date: Date
    let snapshot: TrakiSnapshot
}

/// Shared provider for the static Home/Lock-Screen widgets. Refreshes about
/// every 15 minutes; the app also nudges reloads on data change.
struct SnapshotProvider: TimelineProvider {
    func placeholder(in context: Context) -> SnapshotEntry {
        SnapshotEntry(date: Date(), snapshot: .sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (SnapshotEntry) -> Void) {
        let snapshot = context.isPreview ? .sample : TrakiWidgetData.load()
        completion(SnapshotEntry(date: Date(), snapshot: snapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SnapshotEntry>) -> Void) {
        let now = Date()
        let entry = SnapshotEntry(date: now, snapshot: TrakiWidgetData.load(now: now))
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: now) ?? now
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}
