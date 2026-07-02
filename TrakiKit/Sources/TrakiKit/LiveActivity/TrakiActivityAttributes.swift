import ActivityKit
import Foundation

/// Describes the Live Activity for a running session. The app owns the activity
/// lifecycle; the widget extension renders it on the Lock Screen and in the
/// Dynamic Island.
public struct TrakiActivityAttributes: ActivityAttributes {
    /// The dynamic part, updated as the session runs, pauses and resumes.
    public struct ContentState: Codable, Hashable, Sendable {
        public var modeRaw: String
        public var isRunning: Bool
        /// Start of the current running segment (for a live-ticking clock).
        public var segmentStart: Date
        /// Time accumulated before the current segment (paused display, and to
        /// offset the ticking clock so it shows the *total*).
        public var baseElapsed: TimeInterval

        public init(mode: LearningMode, isRunning: Bool, segmentStart: Date, baseElapsed: TimeInterval) {
            self.modeRaw = mode.rawValue
            self.isRunning = isRunning
            self.segmentStart = segmentStart
            self.baseElapsed = baseElapsed
        }

        public var mode: LearningMode { LearningMode(rawValue: modeRaw) ?? .flashcards }

        /// Effective start so `Text(timerInterval:)` displays the *total* elapsed.
        public var effectiveStart: Date { segmentStart.addingTimeInterval(-baseElapsed) }

        /// Frozen elapsed for the paused state.
        public var frozenElapsed: TimeInterval { baseElapsed }
    }

    public var sessionId: UUID

    public init(sessionId: UUID) { self.sessionId = sessionId }
}
