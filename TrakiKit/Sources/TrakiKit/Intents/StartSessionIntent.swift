import AppIntents
import Foundation

/// Lets `LearningMode` be used as an App Intent parameter (widget buttons, Shortcuts).
extension LearningMode: AppEnum {
    public static var typeDisplayRepresentation: TypeDisplayRepresentation { "Study Mode" }

    public static var caseDisplayRepresentations: [LearningMode: DisplayRepresentation] {
        [
            .flashcards: "Flashcards",
            .listening: "Listening",
            .reading: "Reading",
            .sentenceMining: "Sentence Mining",
        ]
    }
}

/// Opens Traki and immediately starts a session in the chosen mode — the engine
/// behind widget quick-start buttons and the "track without opening" principle.
public struct StartSessionIntent: AppIntent {
    public static let title: LocalizedStringResource = "Start a Session"
    public static let description = IntentDescription("Start tracking a study session in Traki.")
    public static let openAppWhenRun = true

    @Parameter(title: "Mode")
    public var mode: LearningMode

    public init() {}
    public init(mode: LearningMode) { self.mode = mode }

    public func perform() async throws -> some IntentResult {
        TrakiIntentBridge.requestStart(mode)
        return .result()
    }
}

/// Cross-process hand-off: the intent records the requested mode in the shared
/// App Group, and the app consumes it when it becomes active.
public enum TrakiIntentBridge {
    private static let modeKey = "intent.pendingStartMode"
    private static let timestampKey = "intent.pendingStartAt"

    private static var defaults: UserDefaults? { UserDefaults(suiteName: TrakiStore.appGroupID) }

    public static func requestStart(_ mode: LearningMode) {
        defaults?.set(mode.rawValue, forKey: modeKey)
        defaults?.set(Date().timeIntervalSince1970, forKey: timestampKey)
    }

    /// Returns and clears a pending request, ignoring stale ones.
    public static func consumePendingStart(maxAge: TimeInterval = 15) -> LearningMode? {
        guard let defaults, let raw = defaults.string(forKey: modeKey) else { return nil }
        let at = defaults.double(forKey: timestampKey)
        defaults.removeObject(forKey: modeKey)
        defaults.removeObject(forKey: timestampKey)
        guard Date().timeIntervalSince1970 - at <= maxAge else { return nil }
        return LearningMode(rawValue: raw)
    }
}
