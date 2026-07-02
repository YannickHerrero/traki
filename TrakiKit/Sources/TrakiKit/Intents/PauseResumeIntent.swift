import AppIntents

/// Pauses or resumes the running session from the Live Activity (Lock Screen /
/// Dynamic Island). As a `LiveActivityIntent` it runs in the app's process —
/// relaunching it in the background if needed — so it acts on the shared
/// ``SessionController``, which restores the session from the App Group.
public struct PauseResumeIntent: LiveActivityIntent {
    public static let title: LocalizedStringResource = "Pause or Resume Session"

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult {
        SessionController.shared.togglePause()
        return .result()
    }
}
