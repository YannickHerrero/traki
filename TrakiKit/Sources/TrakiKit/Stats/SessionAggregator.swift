import Foundation

/// Derives every figure the UI shows — today/period totals, per-mode splits, the
/// day streak, last-7-days bars, the by-mode breakdown, the 8-week trend, the
/// consistency heatmap and the History groups — from a set of session snapshots.
///
/// Pure and `Sendable`: a value in, values out. Sessions are attributed to the
/// day/period of their `start`.
public struct SessionAggregator: Sendable {
    public let sessions: [SessionSnapshot]
    public let calendar: Calendar
    public let now: Date

    public init(sessions: [SessionSnapshot], calendar: Calendar = .current, now: Date) {
        self.sessions = sessions
        self.calendar = calendar
        self.now = now
    }

    // MARK: Totals

    /// Per-mode seconds for the sessions whose `start` falls in `interval`.
    public func totalsByMode(in interval: DateInterval) -> [LearningMode: Int] {
        var totals: [LearningMode: Int] = [:]
        for s in sessions where interval.contains(s.start) {
            totals[s.mode, default: 0] += s.seconds
        }
        return totals
    }

    /// Total seconds in `interval`.
    public func totalSeconds(in interval: DateInterval) -> Int {
        sessions.reduce(0) { $0 + (interval.contains($1.start) ? $1.seconds : 0) }
    }

    /// Per-mode seconds for a single calendar day.
    public func totalsByMode(onDayStarting day: Date) -> [LearningMode: Int] {
        totalsByMode(in: dayInterval(day))
    }

    /// Total seconds for the calendar day containing `date`.
    public func totalSeconds(onDayOf date: Date) -> Int {
        totalSeconds(in: dayInterval(calendar.startOfDay(for: date)))
    }

    /// Today's total in seconds.
    public var todaySeconds: Int { totalSeconds(onDayOf: now) }

    /// Progress toward a daily goal (whole percent, capped at 100).
    public func goalPercent(dailyGoalMinutes goal: Int) -> Int {
        guard goal > 0 else { return 0 }
        return min(100, Int((Double(todaySeconds) / Double(goal * 60) * 100).rounded()))
    }

    // MARK: Streak

    /// Consecutive days with any tracked time, counting back from today. If today
    /// has nothing yet, the run is measured through yesterday (still "alive").
    public func currentStreak() -> Int {
        let activeDays = Set(sessions.map { calendar.startOfDay(for: $0.start) })
        var day = calendar.startOfDay(for: now)
        if !activeDays.contains(day) {
            day = calendar.date(byAdding: .day, value: -1, to: day)!
        }
        var streak = 0
        while activeDays.contains(day) {
            streak += 1
            day = calendar.date(byAdding: .day, value: -1, to: day)!
        }
        return streak
    }

    // MARK: Period stats (Day / Month / Year)

    /// Total for the current period plus its change versus the previous one.
    public func periodStats(_ period: StatsPeriod) -> PeriodStats {
        let current = totalSeconds(in: periodInterval(period, containing: now))
        let previousDate = calendar.date(byAdding: period.component, value: -1, to: now)!
        let previous = totalSeconds(in: periodInterval(period, containing: previousDate))
        let delta = previous > 0
            ? Int((Double(current - previous) / Double(previous) * 100).rounded())
            : nil
        return PeriodStats(total: current, previousTotal: previous, deltaPercent: delta)
    }

    /// Per-mode breakdown for a period, in canonical mode order.
    public func breakdown(_ period: StatsPeriod) -> [ModeBreakdownItem] {
        let totals = totalsByMode(in: periodInterval(period, containing: now))
        return LearningMode.allCases.map { ModeBreakdownItem(mode: $0, seconds: totals[$0] ?? 0) }
    }

    // MARK: Series

    /// The last `count` days, oldest-first, each with its per-mode totals.
    public func lastDays(_ count: Int) -> [DayBucket] {
        let today = calendar.startOfDay(for: now)
        return (0..<count).reversed().map { offset in
            let day = calendar.date(byAdding: .day, value: -offset, to: today)!
            return DayBucket(date: day, totalsByMode: totalsByMode(onDayStarting: day))
        }
    }

    /// Average daily hours for each of the last `weeks` rolling 7-day windows,
    /// oldest-first — the Stats trend line.
    public func weeklyTrend(weeks: Int) -> [Double] {
        let today = calendar.startOfDay(for: now)
        return (0..<weeks).reversed().map { w in
            let windowEndDay = calendar.date(byAdding: .day, value: -(w * 7), to: today)!
            let windowStart = calendar.date(byAdding: .day, value: -6, to: windowEndDay)!
            let end = calendar.date(byAdding: .day, value: 1, to: windowEndDay)! // exclusive
            let secs = totalSeconds(in: DateInterval(start: windowStart, end: end))
            return Double(secs) / 7.0 / 3600.0
        }
    }

    /// One heatmap cell per day for the last `days` days, oldest-first.
    public func heatmap(days: Int) -> [HeatCell] {
        let today = calendar.startOfDay(for: now)
        return (0..<days).reversed().map { offset in
            let day = calendar.date(byAdding: .day, value: -offset, to: today)!
            let secs = totalSeconds(in: dayInterval(day))
            return HeatCell(date: day, level: Self.level(forSeconds: secs), seconds: secs)
        }
    }

    /// Buckets a day's total into 0…4 for heatmap intensity.
    public static func level(forSeconds s: Int) -> Int {
        switch s {
        case 0: 0
        case ..<(30 * 60): 1
        case ..<(60 * 60): 2
        case ..<(120 * 60): 3
        default: 4
        }
    }

    // MARK: History

    /// Sessions grouped by day, days newest-first and each day's sessions
    /// newest-first, with the day's total.
    public func historyDays() -> [HistoryDay] {
        let grouped = Dictionary(grouping: sessions) { calendar.startOfDay(for: $0.start) }
        return grouped.keys.sorted(by: >).map { day in
            let entries = grouped[day]!
                .sorted { $0.start > $1.start }
                .map { HistoryEntry(id: $0.id, mode: $0.mode, start: $0.start,
                                    seconds: $0.seconds, isManual: $0.isManual) }
            return HistoryDay(date: day, entries: entries,
                              total: entries.reduce(0) { $0 + $1.seconds })
        }
    }

    // MARK: Intervals

    private func dayInterval(_ dayStart: Date) -> DateInterval {
        let start = calendar.startOfDay(for: dayStart)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        return DateInterval(start: start, end: end)
    }

    private func periodInterval(_ period: StatsPeriod, containing date: Date) -> DateInterval {
        calendar.dateInterval(of: period.component, for: date)!
    }
}
