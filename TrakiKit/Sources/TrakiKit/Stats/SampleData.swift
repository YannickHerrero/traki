import Foundation
import SwiftData

/// Deterministic sample sessions for SwiftUI previews, widget placeholders, and
/// DEBUG first-run seeding. Content is a function of the day offset (not wall
/// clock), so it's stable across runs. Today mirrors the prototype exactly so
/// the seeded app opens looking like the design.
public enum SampleData {

    /// A reproducible spread of sessions across the last 16 weeks, ending `now`.
    public static func snapshots(now: Date, calendar: Calendar = .current) -> [SessionSnapshot] {
        var rng = SeededGenerator(seed: 0x5472_616B_6900) // "Traki"
        let today = calendar.startOfDay(for: now)
        let modes = LearningMode.allCases
        var result: [SessionSnapshot] = []

        for offset in 0..<112 {
            let day = calendar.date(byAdding: .day, value: -offset, to: today)!

            // Today matches the prototype's `todaySessions` (1h 42m total).
            if offset == 0 {
                let defs: [(LearningMode, Int, Int)] = [
                    (.listening, 2700, 19), (.flashcards, 1500, 18),
                    (.reading, 1320, 13), (.sentenceMining, 600, 8),
                ]
                for (mode, secs, hour) in defs {
                    let start = calendar.date(bySettingHour: hour, minute: 5, second: 0, of: day)!
                    result.append(SessionSnapshot(id: UUID(), mode: mode, start: start,
                                                  seconds: secs, isManual: false))
                }
                continue
            }

            let weekday = calendar.component(.weekday, from: day) // 1 = Sun … 7 = Sat
            let isWeekend = weekday == 1 || weekday == 7
            var level = Int.random(in: 0...4, using: &rng)
            if isWeekend, level > 0 { level -= 1 }
            if offset <= 22 { level = max(level, 1) } // keep a ~23-day streak alive
            if offset > 84, level > 2 { level -= 1 }  // older weeks a touch quieter

            for i in 0..<level {
                let mode = modes[Int.random(in: 0..<modes.count, using: &rng)]
                let minutes = [10, 15, 20, 25, 30, 40, 45, 60][Int.random(in: 0..<8, using: &rng)]
                let hour = min(8 + i * 3 + Int.random(in: 0...1, using: &rng), 22)
                let start = calendar.date(bySettingHour: hour,
                                          minute: Int.random(in: 0...55, using: &rng),
                                          second: 0, of: day)!
                result.append(SessionSnapshot(id: UUID(), mode: mode, start: start,
                                              seconds: minutes * 60, isManual: false))
            }
        }
        return result
    }

    /// Seeds an empty store with the sample sessions; a no-op if any exist.
    @MainActor
    public static func seedIfEmpty(_ context: ModelContext,
                                   now: Date = Date(),
                                   calendar: Calendar = .current) {
        let existing = (try? context.fetchCount(FetchDescriptor<Session>())) ?? 0
        guard existing == 0 else { return }
        for snap in snapshots(now: now, calendar: calendar) {
            context.insert(Session(id: snap.id, mode: snap.mode, startDate: snap.start,
                                   durationSeconds: snap.seconds, isManual: snap.isManual))
        }
        try? context.save()
    }
}

/// Small seedable PRNG so sample data (and any tests) are reproducible.
/// SplitMix64 — fast, good distribution, fully deterministic.
public struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    public init(seed: UInt64) { state = seed &+ 0x9E37_79B9_7F4A_7C15 }
    public mutating func next() -> UInt64 {
        state = state &+ 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
