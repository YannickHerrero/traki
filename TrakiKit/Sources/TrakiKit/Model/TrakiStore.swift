import Foundation
import SwiftData

/// Builds the shared SwiftData container.
///
/// The store lives in the **App Group** container so the app and its widget /
/// Live-Activity extensions read and write the same database. Until that
/// entitlement is added (Phase 9) the group URL resolves to `nil`, so we fall
/// back to a local app-sandbox store — the app runs identically in either case,
/// and picks up the shared store automatically once the entitlement lands.
public enum TrakiStore {
    public static let appGroupID = "group.com.yannickherrero.traki"

    /// Whether the App Group entitlement is currently available to this process.
    public static var appGroupAvailable: Bool {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) != nil
    }

    @MainActor
    public static func makeContainer(inMemory: Bool = false) -> ModelContainer {
        let schema = Schema([Session.self])
        let configuration: ModelConfiguration

        if inMemory {
            configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        } else if appGroupAvailable {
            configuration = ModelConfiguration(schema: schema, groupContainer: .identifier(appGroupID))
        } else {
            configuration = ModelConfiguration(schema: schema)
        }

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Unable to create Traki ModelContainer: \(error)")
        }
    }
}
