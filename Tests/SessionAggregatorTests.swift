import Foundation
import Testing
@testable import TrakiKit

struct SessionAggregatorTests {

    /// Fixed UTC calendar + reference date so day math never depends on the
    /// machine's timezone. "Now" is 2026-07-01 20:00 UTC (a Wednesday).
    private var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }
    private var now: Date {
        calendar.date(from: DateComponents(year: 2026, month: 7, day: 1, hour: 20))!
    }
    private func day(_ offset: Int, hour: Int = 12) -> Date {
        let today = calendar.startOfDay(for: now)
        return calendar.date(byAdding: .day, value: -offset, to: today)!
            .addingTimeInterval(TimeInterval(hour * 3600))
    }
    private func snap(_ mode: LearningMode, _ start: Date, minutes: Int) -> SessionSnapshot {
        SessionSnapshot(id: UUID(), mode: mode, start: start, seconds: minutes * 60, isManual: false)
    }
    private func agg(_ sessions: [SessionSnapshot]) -> SessionAggregator {
        SessionAggregator(sessions: sessions, calendar: calendar, now: now)
    }

    @Test func todayTotalsAndGoal() {
        let a = agg([
            snap(.listening, day(0, hour: 19), minutes: 45),
            snap(.flashcards, day(0, hour: 18), minutes: 25),
            snap(.reading, day(0, hour: 13), minutes: 22),
            snap(.sentenceMining, day(0, hour: 8), minutes: 10),
            snap(.reading, day(1), minutes: 30), // yesterday, excluded from today
        ])
        #expect(a.todaySeconds == (45 + 25 + 22 + 10) * 60) // 6120
        #expect(a.totalsByMode(onDayStarting: calendar.startOfDay(for: now))[.listening] == 2700)
        #expect(a.goalPercent(dailyGoalMinutes: 120) == 85) // 102 / 120
        #expect(a.goalPercent(dailyGoalMinutes: 60) == 100) // capped
    }

    @Test func streakCountsConsecutiveDaysFromToday() {
        let a = agg([snap(.reading, day(0), minutes: 10),
                     snap(.reading, day(1), minutes: 10),
                     snap(.reading, day(2), minutes: 10)])
        #expect(a.currentStreak() == 3)
    }

    @Test func streakAliveThroughYesterdayWhenTodayEmpty() {
        let a = agg([snap(.reading, day(1), minutes: 10),
                     snap(.reading, day(2), minutes: 10)])
        #expect(a.currentStreak() == 2)
    }

    @Test func streakBreaksOnGap() {
        let a = agg([snap(.reading, day(0), minutes: 10),
                     snap(.reading, day(2), minutes: 10)]) // day(1) missing
        #expect(a.currentStreak() == 1)
    }

    @Test func periodDeltaVersusPreviousDay() {
        let a = agg([snap(.reading, day(0), minutes: 100),
                     snap(.reading, day(1), minutes: 50)])
        let stats = a.periodStats(.day)
        #expect(stats.total == 6000)
        #expect(stats.previousTotal == 3000)
        #expect(stats.deltaPercent == 100)
    }

    @Test func periodDeltaNilWhenPreviousEmpty() {
        let a = agg([snap(.reading, day(0), minutes: 30)])
        #expect(a.periodStats(.day).deltaPercent == nil)
    }

    @Test func heatmapLevelThresholds() {
        #expect(SessionAggregator.level(forSeconds: 0) == 0)
        #expect(SessionAggregator.level(forSeconds: 1799) == 1)
        #expect(SessionAggregator.level(forSeconds: 1800) == 2)
        #expect(SessionAggregator.level(forSeconds: 3599) == 2)
        #expect(SessionAggregator.level(forSeconds: 3600) == 3)
        #expect(SessionAggregator.level(forSeconds: 7199) == 3)
        #expect(SessionAggregator.level(forSeconds: 7200) == 4)
    }

    @Test func historyGroupsByDayNewestFirst() {
        let a = agg([
            snap(.reading, day(0, hour: 9), minutes: 20),
            snap(.listening, day(0, hour: 19), minutes: 40),
            snap(.flashcards, day(1, hour: 8), minutes: 15),
        ])
        let days = a.historyDays()
        #expect(days.count == 2)
        #expect(days[0].total == 60 * 60)               // today: 20 + 40 min
        #expect(days[0].entries.first?.mode == .listening) // newest-first within day
        #expect(days[1].total == 15 * 60)
    }

    @Test func lastDaysHasRequestedCountOldestFirst() {
        let a = agg([snap(.reading, day(0), minutes: 10)])
        let buckets = a.lastDays(7)
        #expect(buckets.count == 7)
        #expect(buckets.last?.total == 10 * 60)  // last element is today
        #expect(buckets.first?.total == 0)
    }
}
