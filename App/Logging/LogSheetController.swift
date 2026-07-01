import Foundation
import Observation
import TrakiKit

/// Presentation + draft state for the "Log a session" / "Edit session" sheet,
/// shared so both Home (log a past session) and History (hold to edit) drive the
/// same sheet. Duration is clamped to 5–240 minutes to match the prototype.
@MainActor
@Observable
final class LogSheetController {
    var isPresented = false
    var mode: LearningMode = .flashcards
    var minutes: Int = 15
    var isYesterday = false
    /// The session being edited, or `nil` for a new manual entry.
    var editing: Session?

    var isEditing: Bool { editing != nil }

    func openNew(defaultMode: LearningMode) {
        editing = nil
        mode = defaultMode
        minutes = 15
        isYesterday = false
        isPresented = true
    }

    func openEdit(_ session: Session) {
        editing = session
        mode = session.mode
        minutes = min(240, max(5, Int((Double(session.durationSeconds) / 60).rounded())))
        isPresented = true
    }

    func setMinutes(_ value: Int) {
        minutes = min(240, max(5, value))
    }
}
