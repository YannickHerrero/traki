import SwiftData
import SwiftUI
import TrakiKit

/// The launchpad — greeting, streak, goal, resume hero, mode cards, log-past.
/// Answers "what do you want to study right now?" and gets out of the way.
struct HomeScreen: View {
    @Environment(\.palette) private var palette
    @Environment(AppSettings.self) private var settings
    @Query(sort: \Session.startDate, order: .reverse) private var sessions: [Session]

    var body: some View {
        let now = Date()
        let agg = SessionAggregator(sessions: sessions.map(\.snapshot), now: now)

        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header(streak: agg.currentStreak(), now: now)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: Header

    private func header(streak: Int, now: Date) -> some View {
        HStack(alignment: .center) {
            Text(greeting(now))
                .font(.nunito(26, .heavy))
                .foregroundStyle(palette.text)
            Spacer(minLength: 8)
            streakPill(streak)
        }
    }

    private func streakPill(_ streak: Int) -> some View {
        HStack(spacing: 5) {
            Text("\(streak)")
                .font(.nunito(15, .heavy))
            Text("day streak")
                .font(.nunito(11, .bold))
        }
        .foregroundStyle(LearningMode.flashcards.ink(dark: palette.isDark))
        .padding(.vertical, 7)
        .padding(.horizontal, 12)
        .background(LearningMode.flashcards.baseColor.opacity(0.18), in: .capsule)
    }

    private func greeting(_ now: Date) -> String {
        switch Calendar.current.component(.hour, from: now) {
        case ..<12: "Good morning"
        case ..<18: "Good afternoon"
        default: "Good evening"
        }
    }
}

#Preview {
    let container = TrakiStore.makeContainer(inMemory: true)
    SampleData.seedIfEmpty(container.mainContext)
    return HomeScreen()
        .environment(AppSettings())
        .environment(\.palette, .light)
        .modelContainer(container)
}
