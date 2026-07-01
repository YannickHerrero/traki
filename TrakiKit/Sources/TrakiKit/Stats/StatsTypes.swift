import Foundation

/// The statistics period switch on the Stats screen.
public enum StatsPeriod: String, CaseIterable, Identifiable, Sendable {
    case day = "Day"
    case month = "Month"
    case year = "Year"

    public var id: String { rawValue }

    /// Heading for the total, e.g. "Today" / "This month" / "This year".
    public var totalLabel: String {
        switch self {
        case .day: "Today"
        case .month: "This month"
        case .year: "This year"
        }
    }

    var component: Calendar.Component {
        switch self {
        case .day: .day
        case .month: .month
        case .year: .year
        }
    }
}

/// One day's per-mode totals (last-7-days bars, trend, heatmap source).
public struct DayBucket: Identifiable, Sendable {
    public let date: Date
    public let totalsByMode: [LearningMode: Int]
    public var total: Int { totalsByMode.values.reduce(0, +) }
    public var id: Date { date }

    public func seconds(_ mode: LearningMode) -> Int { totalsByMode[mode] ?? 0 }
}

/// A mode's share of a period, for the "By category" breakdown.
public struct ModeBreakdownItem: Identifiable, Sendable {
    public let mode: LearningMode
    public let seconds: Int
    public var id: String { mode.rawValue }
}

/// A period total paired with its change versus the previous period.
public struct PeriodStats: Sendable {
    public let total: Int
    public let previousTotal: Int
    /// Percent change vs. the previous period; `nil` when the previous period was empty.
    public let deltaPercent: Int?
}

/// One heatmap square: a day and its intensity level (0…4).
public struct HeatCell: Identifiable, Sendable {
    public let date: Date
    public let level: Int
    public let seconds: Int
    public var id: Date { date }
}

/// One session as shown in History.
public struct HistoryEntry: Identifiable, Sendable {
    public let id: UUID
    public let mode: LearningMode
    public let start: Date
    public let seconds: Int
    public let isManual: Bool
}

/// A day heading in History with its sessions (newest-first) and day total.
public struct HistoryDay: Identifiable, Sendable {
    public let date: Date
    public let entries: [HistoryEntry]
    public let total: Int
    public var id: Date { date }
}
