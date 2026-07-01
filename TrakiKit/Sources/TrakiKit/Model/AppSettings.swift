import Foundation
import Observation

/// User preferences from the Settings screen, persisted in the App Group so the
/// app and its extensions share them. Observable, so SwiftUI views update the
/// instant a value changes.
///
/// Widgets read the handful of values they need straight from
/// `UserDefaults(suiteName:)` rather than through this main-actor object.
@MainActor
@Observable
public final class AppSettings {
    @ObservationIgnored private let defaults: UserDefaults

    // MARK: Learning
    public var theme: AppTheme { didSet { defaults.set(theme.rawValue, forKey: Keys.theme) } }
    public var dailyGoalMinutes: Int { didSet { defaults.set(dailyGoalMinutes, forKey: Keys.goal) } }
    public var language: String { didSet { defaults.set(language, forKey: Keys.language) } }
    public var activeModes: Set<LearningMode> {
        didSet { defaults.set(activeModes.map(\.rawValue).sorted(), forKey: Keys.activeModes) }
    }

    // MARK: Tracking
    public var autoPauseWhenIdle: Bool { didSet { defaults.set(autoPauseWhenIdle, forKey: Keys.autoPause) } }
    public var showLiveActivity: Bool { didSet { defaults.set(showLiveActivity, forKey: Keys.liveActivity) } }
    public var roundToNearestMinute: Bool { didSet { defaults.set(roundToNearestMinute, forKey: Keys.round) } }

    public init(defaults: UserDefaults? = nil) {
        let store = defaults ?? UserDefaults(suiteName: TrakiStore.appGroupID) ?? .standard
        self.defaults = store

        self.theme = AppTheme(rawValue: store.string(forKey: Keys.theme) ?? "") ?? .system
        self.dailyGoalMinutes = store.object(forKey: Keys.goal) as? Int ?? 120
        self.language = store.string(forKey: Keys.language) ?? "Japanese"
        if let raw = store.array(forKey: Keys.activeModes) as? [String] {
            self.activeModes = Set(raw.compactMap(LearningMode.init(rawValue:)))
        } else {
            self.activeModes = Set(LearningMode.allCases)
        }
        self.autoPauseWhenIdle = store.object(forKey: Keys.autoPause) as? Bool ?? true
        self.showLiveActivity = store.object(forKey: Keys.liveActivity) as? Bool ?? true
        self.roundToNearestMinute = store.object(forKey: Keys.round) as? Bool ?? false
    }

    /// Modes to show, always in canonical order.
    public var orderedActiveModes: [LearningMode] {
        LearningMode.allCases.filter(activeModes.contains)
    }

    public func isActive(_ mode: LearningMode) -> Bool { activeModes.contains(mode) }

    private enum Keys {
        static let theme = "settings.theme"
        static let goal = "settings.dailyGoalMinutes"
        static let language = "settings.language"
        static let activeModes = "settings.activeModes"
        static let autoPause = "settings.autoPauseWhenIdle"
        static let liveActivity = "settings.showLiveActivity"
        static let round = "settings.roundToNearestMinute"
    }
}
