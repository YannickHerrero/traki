import Foundation

/// Duration and clock formatting, ported verbatim from the prototype's
/// `fmtDur` / `fmtClock` so totals read identically to the design.
public enum TrakiFormat {

    /// Human-readable duration.
    ///
    /// - `1h 42m`, or `2h` when the minutes are zero
    /// - `45m` for sub-hour durations
    /// - `3m 20s` **only** when under 10 minutes and there are stray seconds
    /// - `45s` for sub-minute durations
    ///
    /// Seconds are rounded to the nearest whole second first (matches the design).
    public static func duration(_ seconds: Double) -> String {
        let s = Int(seconds.rounded())
        let h = s / 3600, m = (s % 3600) / 60, sec = s % 60
        if h > 0 { return m > 0 ? "\(h)h \(m)m" : "\(h)h" }
        if m > 0 { return (s < 600 && sec > 0) ? "\(m)m \(sec)s" : "\(m)m" }
        return "\(sec)s"
    }

    public static func duration(_ seconds: Int) -> String { duration(Double(seconds)) }

    /// Stopwatch clock: `MM:SS`, promoting to `H:MM:SS` once past an hour.
    /// Seconds are floored (a running clock never rounds up).
    public static func clock(_ seconds: Double) -> String {
        let s = Int(seconds.rounded(.down))
        let h = s / 3600, m = (s % 3600) / 60, sec = s % 60
        func pad(_ n: Int) -> String { String(format: "%02d", n) }
        return h > 0 ? "\(h):\(pad(m)):\(pad(sec))" : "\(pad(m)):\(pad(sec))"
    }

    public static func clock(_ seconds: Int) -> String { clock(Double(seconds)) }
}
