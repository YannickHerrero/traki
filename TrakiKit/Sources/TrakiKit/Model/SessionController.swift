import ActivityKit
import Foundation
import Observation

/// Drives the one running session: start, pause/resume, and stop. Elapsed time
/// is computed from the wall clock (accumulated segments + the current run), so
/// it stays correct across pauses and view redraws without a ticking timer —
/// the Active Timer view refreshes the display with a `TimelineView`.
///
/// Persistence lives at the call site: `stop` returns the finished session and
/// the caller inserts a `Session`. Only one session runs at a time.
@MainActor
@Observable
public final class SessionController {
    public enum Phase: Sendable { case idle, running, paused, completed }

    public private(set) var mode: LearningMode?
    public private(set) var phase: Phase = .idle
    public private(set) var sessionStart: Date?
    public private(set) var completed: CompletedSession?

    private var accumulated: TimeInterval = 0
    private var segmentStart: Date?

    /// Whether to show a Lock-Screen Live Activity for running sessions. The app
    /// keeps this in sync with the Settings toggle.
    public var liveActivitiesEnabled = true
    private var activity: Activity<TrakiActivityAttributes>?

    public struct CompletedSession: Sendable {
        public let mode: LearningMode
        public let seconds: Int
        public let startDate: Date
    }

    public init() {}

    public var isActive: Bool { phase == .running || phase == .paused }
    public var isRunning: Bool { phase == .running }

    public func start(_ mode: LearningMode, at date: Date = Date()) {
        self.mode = mode
        sessionStart = date
        accumulated = 0
        segmentStart = date
        completed = nil
        phase = .running
        startActivity()
    }

    public func pause(at date: Date = Date()) {
        guard phase == .running, let segment = segmentStart else { return }
        accumulated += date.timeIntervalSince(segment)
        segmentStart = nil
        phase = .paused
        updateActivity()
    }

    public func resume(at date: Date = Date()) {
        guard phase == .paused else { return }
        segmentStart = date
        phase = .running
        updateActivity()
    }

    public func togglePause(at date: Date = Date()) {
        phase == .running ? pause(at: date) : resume(at: date)
    }

    /// Seconds elapsed as of `date` (accumulated segments plus the live run).
    public func elapsed(at date: Date = Date()) -> TimeInterval {
        accumulated + (phase == .running ? date.timeIntervalSince(segmentStart ?? date) : 0)
    }

    /// Ends the session and moves to `.completed`, returning the finished data
    /// (at least 1s, optionally rounded to the nearest minute) for persistence.
    @discardableResult
    public func stop(at date: Date = Date(), roundToMinute: Bool = false) -> CompletedSession? {
        guard let mode, let start = sessionStart else { return nil }
        var seconds = Int(elapsed(at: date).rounded())
        if roundToMinute { seconds = Int((Double(seconds) / 60).rounded()) * 60 }
        seconds = max(1, seconds)
        let done = CompletedSession(mode: mode, seconds: seconds, startDate: start)
        completed = done
        segmentStart = nil
        phase = .completed
        endActivity()
        return done
    }

    /// Returns to idle (after the Complete screen is dismissed).
    public func clear() {
        endActivity()
        mode = nil
        sessionStart = nil
        segmentStart = nil
        accumulated = 0
        completed = nil
        phase = .idle
    }

    // MARK: Live Activity

    private func currentContentState() -> TrakiActivityAttributes.ContentState {
        TrakiActivityAttributes.ContentState(
            mode: mode ?? .flashcards,
            isRunning: phase == .running,
            segmentStart: segmentStart ?? Date(),
            baseElapsed: accumulated)
    }

    private func startActivity() {
        guard liveActivitiesEnabled, activity == nil,
              ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let attributes = TrakiActivityAttributes(sessionId: UUID())
        let content = ActivityContent(state: currentContentState(), staleDate: nil)
        activity = try? Activity.request(attributes: attributes, content: content)
    }

    private func updateActivity() {
        guard let activity else { return }
        let content = ActivityContent(state: currentContentState(), staleDate: nil)
        Task { await activity.update(content) }
    }

    private func endActivity() {
        guard let activity else { return }
        let content = ActivityContent(state: currentContentState(), staleDate: nil)
        Task { await activity.end(content, dismissalPolicy: .immediate) }
        self.activity = nil
    }
}
