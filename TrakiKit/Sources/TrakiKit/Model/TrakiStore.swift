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
    public static let cloudKitContainerID = "iCloud.com.yannickherrero.traki"

    /// Whether the App Group entitlement is currently available to this process.
    public static var appGroupAvailable: Bool {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) != nil
    }

    /// Not main-actor isolated: the app builds this on the main actor and uses
    /// `mainContext`, while the widget builds it off-main and uses a fresh
    /// `ModelContext`. Container creation itself has no actor requirement.
    ///
    /// `cloudSync` mirrors the store to the user's private CloudKit database.
    /// Only the app passes `true`: the widget reads the same App Group store
    /// file, but extensions lack the iCloud entitlement and can't receive the
    /// pushes that drive sync, so they open it with CloudKit off.
    public static func makeContainer(inMemory: Bool = false, cloudSync: Bool = false) -> ModelContainer {
        let schema = Schema([Session.self])

        func makeConfiguration(cloudKit: ModelConfiguration.CloudKitDatabase) -> ModelConfiguration {
            if inMemory {
                return ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
            } else if appGroupAvailable {
                return ModelConfiguration(schema: schema, groupContainer: .identifier(appGroupID),
                                          cloudKitDatabase: cloudKit)
            } else {
                return ModelConfiguration(schema: schema, cloudKitDatabase: cloudKit)
            }
        }

        let wantsCloud = cloudSync && !inMemory
        do {
            return try ModelContainer(
                for: schema,
                configurations: [makeConfiguration(cloudKit: wantsCloud ? .private(cloudKitContainerID) : .none)]
            )
        } catch {
            // CloudKit can be unavailable (build signed without the iCloud
            // entitlement, signed-out account, …) — a local-only store beats
            // crashing, and sync picks the data up on a later launch.
            if wantsCloud,
               let localOnly = try? ModelContainer(for: schema,
                                                   configurations: [makeConfiguration(cloudKit: .none)]) {
                return localOnly
            }
            fatalError("Unable to create Traki ModelContainer: \(error)")
        }
    }

    /// One-time migration from the local sandbox store to the App Group store.
    ///
    /// An early TestFlight build ran without the App Group and therefore wrote to
    /// the app's local database; once the App Group is present the app reads the
    /// shared store instead, which would otherwise look empty. This copies any
    /// sessions from the old local store into the group store, merging by id, so
    /// updating never loses history. Runs at most once.
    @MainActor
    public static func migrateLocalStoreIfNeeded(into groupContainer: ModelContainer) {
        guard appGroupAvailable else { return }
        let defaults = UserDefaults(suiteName: appGroupID) ?? .standard
        let flag = "didMigrateLocalStore.v1"
        guard !defaults.bool(forKey: flag) else { return }
        defer { defaults.set(true, forKey: flag) }

        let schema = Schema([Session.self])
        // `.none` forces the app-local sandbox location where the old build wrote.
        guard let localContainer = try? ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(schema: schema, groupContainer: .none)]
        ) else { return }

        let oldSessions = (try? ModelContext(localContainer).fetch(FetchDescriptor<Session>())) ?? []
        guard !oldSessions.isEmpty else { return }

        let context = groupContainer.mainContext
        let existingIDs = Set(((try? context.fetch(FetchDescriptor<Session>())) ?? []).map(\.id))
        for session in oldSessions where !existingIDs.contains(session.id) {
            context.insert(Session(id: session.id, mode: session.mode, startDate: session.startDate,
                                   durationSeconds: session.durationSeconds, isManual: session.isManual))
        }
        try? context.save()
    }
}
