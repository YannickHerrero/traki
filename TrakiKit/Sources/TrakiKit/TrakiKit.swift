import Foundation

/// Shared core for the Traki app and its widget/Live-Activity extensions.
///
/// Everything the app and widgets both need — the `Session` model and SwiftData
/// store, the four `LearningMode`s, the design palette and fonts, formatters,
/// aggregations, and the App Intents / Live Activity types — lives here so a
/// single source of truth backs every target.
public enum TrakiKit {
    /// Marketing version, mirrored from the app target.
    public static let version = "1.0"
}
