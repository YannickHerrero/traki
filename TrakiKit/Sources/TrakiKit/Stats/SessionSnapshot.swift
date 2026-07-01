import Foundation

/// An immutable value copy of a `Session`, used by the stats layer.
///
/// Aggregation runs over snapshots rather than SwiftData models so it stays a
/// set of pure, `Sendable`, unit-testable functions with no persistence or
/// concurrency entanglement.
public struct SessionSnapshot: Identifiable, Sendable, Hashable {
    public let id: UUID
    public let mode: LearningMode
    public let start: Date
    public let seconds: Int
    public let isManual: Bool

    public init(id: UUID, mode: LearningMode, start: Date, seconds: Int, isManual: Bool) {
        self.id = id
        self.mode = mode
        self.start = start
        self.seconds = seconds
        self.isManual = isManual
    }

    public init(_ session: Session) {
        self.init(id: session.id, mode: session.mode, start: session.startDate,
                  seconds: session.durationSeconds, isManual: session.isManual)
    }

    public var end: Date { start.addingTimeInterval(TimeInterval(seconds)) }
}

public extension Session {
    var snapshot: SessionSnapshot { SessionSnapshot(self) }
}
