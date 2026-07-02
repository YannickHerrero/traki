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

    /// Shared instance used by the app *and* the Live Activity intents, so one
    /// running session is visible to both — even if a Lock-Screen button relaunches
    /// the app in the background. Restores any in-progress session on first access.
    public static let shared = SessionController()

    public init() { restorePersisted() }

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
        persist()
    }

    public func pause(at date: Date = Date()) {
        guard phase == .running, let segment = segmentStart else { return }
        accumulated += date.timeIntervalSince(segment)
        segmentStart = nil
        phase = .paused
        updateActivity()
        persist()
    }

    public func resume(at date: Date = Date()) {
        guard phase == .paused else { return }
        segmentStart = date
        phase = .running
        updateActivity()
        persist()
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
        persist()
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
        persist()
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

    /// The held activity, or the process's current one (after a background relaunch
    /// the intent's fresh controller won't hold a reference).
    private var currentActivity: Activity<TrakiActivityAttributes>? {
        activity ?? Activity<TrakiActivityAttributes>.activities.first
    }

    private func updateActivity() {
        guard let target = currentActivity else { return }
        activity = target
        let content = ActivityContent(state: currentContentState(), staleDate: nil)
        // ActivityKit's async methods are nonisolated and Activity isn't Sendable;
        // the calls are thread-safe, so opt out of the region check for the hand-off.
        nonisolated(unsafe) let handoff = target
        Task { await handoff.update(content) }
    }

    private func endActivity() {
        guard let target = currentActivity else { return }
        let content = ActivityContent(state: currentContentState(), staleDate: nil)
        nonisolated(unsafe) let handoff = target
        activity = nil
        Task { await handoff.end(content, dismissalPolicy: .immediate) }
    }

    // MARK: Persistence (App Group)

    private struct PersistedSession: Codable {
        var modeRaw: String
        var sessionStart: Date
        var accumulated: TimeInterval
        var segmentStart: Date?
        var isRunning: Bool
    }

    private static let persistKey = "session.live.v1"

    private var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: TrakiStore.appGroupID) ?? .standard
    }

    /// Mirrors the running session to the App Group so a Live Activity intent can
    /// act on it even if the app was terminated. Cleared when not tracking.
    private func persist() {
        guard isActive, let mode, let start = sessionStart else {
            sharedDefaults.removeObject(forKey: Self.persistKey)
            return
        }
        let snapshot = PersistedSession(modeRaw: mode.rawValue, sessionStart: start,
                                        accumulated: accumulated, segmentStart: segmentStart,
                                        isRunning: phase == .running)
        if let data = try? JSONEncoder().encode(snapshot) {
            sharedDefaults.set(data, forKey: Self.persistKey)
        }
    }

    private func restorePersisted() {
        guard let data = sharedDefaults.data(forKey: Self.persistKey),
              let snapshot = try? JSONDecoder().decode(PersistedSession.self, from: data),
              let restoredMode = LearningMode(rawValue: snapshot.modeRaw) else { return }
        mode = restoredMode
        sessionStart = snapshot.sessionStart
        accumulated = snapshot.accumulated
        segmentStart = snapshot.segmentStart
        phase = snapshot.isRunning ? .running : .paused
        activity = Activity<TrakiActivityAttributes>.activities.first
    }
}
