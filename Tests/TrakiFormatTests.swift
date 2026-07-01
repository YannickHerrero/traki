import Testing
@testable import TrakiKit

struct TrakiFormatTests {

    @Test func durationHoursAndMinutes() {
        #expect(TrakiFormat.duration(6120) == "1h 42m") // prototype's today total
        #expect(TrakiFormat.duration(3600) == "1h")
        #expect(TrakiFormat.duration(3660) == "1h 1m")
    }

    @Test func durationMinutes() {
        #expect(TrakiFormat.duration(1500) == "25m")
        // Seconds only appear under 10 minutes.
        #expect(TrakiFormat.duration(90) == "1m 30s")
        #expect(TrakiFormat.duration(599) == "9m 59s")
        #expect(TrakiFormat.duration(630) == "10m")   // >= 600s → no seconds
    }

    @Test func durationSeconds() {
        #expect(TrakiFormat.duration(45) == "45s")
        #expect(TrakiFormat.duration(0) == "0s")
    }

    @Test func durationRoundsFractionalSeconds() {
        #expect(TrakiFormat.duration(44.6) == "45s")
    }

    @Test func clockFormats() {
        #expect(TrakiFormat.clock(6120) == "1:42:00")
        #expect(TrakiFormat.clock(62) == "01:02")
        #expect(TrakiFormat.clock(3661) == "1:01:01")
        #expect(TrakiFormat.clock(0) == "00:00")
    }

    @Test func clockFloorsFractionalSeconds() {
        #expect(TrakiFormat.clock(61.9) == "01:01")
    }
}
