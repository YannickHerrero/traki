import SwiftData
import SwiftUI
import TrakiKit

/// The launchpad — greeting, streak, goal, resume hero, mode cards, log-past.
/// Answers "what do you want to study right now?" and gets out of the way.
struct HomeScreen: View {
    @Environment(\.palette) private var palette
    @Environment(AppSettings.self) private var settings
    @Environment(SessionController.self) private var controller
    @Environment(LogSheetController.self) private var logSheet
    @Query(sort: \Session.startDate, order: .reverse) private var sessions: [Session]

    var body: some View {
        let now = Date()
        let agg = SessionAggregator(sessions: sessions.map(\.snapshot), now: now)
        let todayByMode = agg.totalsByMode(onDayStarting: Calendar.current.startOfDay(for: now))
        let lastMode = sessions.first?.mode ?? .listening

        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header(streak: agg.currentStreak(), now: now)
                goalStrip(agg)
                resumeHero(mode: lastMode, todaySeconds: todayByMode[lastMode] ?? 0)
                modeGrid(todayByMode)
                logPastButton(defaultMode: lastMode)
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

    // MARK: Log a past session

    private func logPastButton(defaultMode: LearningMode) -> some View {
        Button {
            // Default to the last mode, but only if it's still an active category.
            let mode = settings.isActive(defaultMode) ? defaultMode
                : (settings.orderedActiveModes.first ?? defaultMode)
            logSheet.openNew(defaultMode: mode)
        } label: {
            HStack(spacing: 9) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                Text("Log a past session")
                    .font(.nunito(14, .heavy))
            }
            .foregroundStyle(palette.faint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(palette.track, style: StrokeStyle(lineWidth: 2, dash: [6, 5]))
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("log-past")
    }

    // MARK: Mode grid

    private func modeGrid(_ todayByMode: [LearningMode: Int]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("OR START SOMETHING NEW")
                .font(.nunito(12, .heavy))
                .tracking(0.5)
                .foregroundStyle(palette.faint)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(settings.orderedActiveModes) { mode in
                    modeCard(mode, seconds: todayByMode[mode] ?? 0)
                }
            }
        }
    }

    private func modeCard(_ mode: LearningMode, seconds: Int) -> some View {
        Button {
            controller.start(mode)
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(mode.baseColor)
                        .frame(width: 40, height: 40)
                    Image(systemName: mode.symbolName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(palette.bg)
                }
                Spacer(minLength: 0)
                Text(mode.displayName)
                    .font(.nunito(16, .heavy))
                    .foregroundStyle(mode.ink(dark: palette.isDark))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(TrakiFormat.duration(seconds))
                    .font(.nunito(13, .bold))
                    .foregroundStyle(palette.faint)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 120)
            .padding(18)
            .background(mode.baseColor.opacity(0.15), in: .rect(cornerRadius: 24, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("mode-\(mode.rawValue)")
    }

    // MARK: Resume hero

    private func resumeHero(mode: LearningMode, todaySeconds: Int) -> some View {
        Button {
            controller.start(mode)
        } label: {
            HStack(spacing: 15) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.white.opacity(0.22))
                        .frame(width: 56, height: 56)
                    Image(systemName: "play.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("PICK UP WHERE YOU LEFT OFF")
                        .font(.nunito(11.5, .bold))
                        .tracking(0.6)
                        .foregroundStyle(.white.opacity(0.82))
                    Text(mode.displayName)
                        .font(.nunito(25, .heavy))
                        .foregroundStyle(.white)
                    Text("\(TrakiFormat.duration(todaySeconds)) done today")
                        .font(.nunito(13, .bold))
                        .foregroundStyle(.white.opacity(0.8))
                }
                Spacer(minLength: 0)
            }
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(mode.heroGradient, in: .rect(cornerRadius: 28, style: .continuous))
            .shadow(color: mode.gradientPartner.opacity(0.35), radius: 12, y: 12)
        }
        .buttonStyle(.plain)
    }

    // MARK: Goal strip

    private func goalStrip(_ agg: SessionAggregator) -> some View {
        let pct = agg.goalPercent(dailyGoalMinutes: settings.dailyGoalMinutes)
        return HStack(spacing: 12) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(palette.track)
                    Capsule()
                        .fill(LinearGradient(
                            colors: [LearningMode.sentenceMining.baseColor,
                                     LearningMode.reading.baseColor],
                            startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * CGFloat(pct) / 100)
                }
            }
            .frame(height: 9)

            Text("\(TrakiFormat.duration(agg.todaySeconds)) · \(pct)%")
                .font(.nunito(12.5, .heavy))
                .foregroundStyle(palette.faint)
                .fixedSize()
        }
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
        .environment(SessionController())
        .environment(LogSheetController())
        .environment(\.palette, .light)
        .modelContainer(container)
}
