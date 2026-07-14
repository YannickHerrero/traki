import Foundation
import SwiftData

/// One tracked study session — the app's single unit of truth. Every total,
/// streak, chart and heatmap is **derived** from these rows, so adding, editing
/// or deleting a `Session` keeps the whole app consistent.
///
/// Every property carries a default value: CloudKit-backed SwiftData requires
/// all attributes to be optional or defaulted (and forbids `.unique`).
@Model
public final class Session {
    /// Stable identity (also used to match a Live Activity to its session).
    public var id: UUID = UUID()
    /// Persisted `LearningMode.rawValue` (`flash`/`listen`/`read`/`mine`).
    public var modeRaw: String = LearningMode.flashcards.rawValue
    /// When the session began.
    public var startDate: Date = Date.now
    /// Length in whole seconds.
    public var durationSeconds: Int = 0
    /// `true` when entered by hand (log-past) rather than timed.
    public var isManual: Bool = false

    public init(id: UUID = UUID(),
                mode: LearningMode,
                startDate: Date,
                durationSeconds: Int,
                isManual: Bool = false) {
        self.id = id
        self.modeRaw = mode.rawValue
        self.startDate = startDate
        self.durationSeconds = durationSeconds
        self.isManual = isManual
    }

    /// Typed accessor over `modeRaw`.
    public var mode: LearningMode {
        get { LearningMode(rawValue: modeRaw) ?? .flashcards }
        set { modeRaw = newValue.rawValue }
    }

    public var duration: TimeInterval { TimeInterval(durationSeconds) }
    public var endDate: Date { startDate.addingTimeInterval(duration) }
}
