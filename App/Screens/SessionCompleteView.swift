import SwiftData
import SwiftUI
import TrakiKit

/// A short, rewarding confirmation that the time was captured: the session
/// length, the mode, and three quick stats (that mode's total today, the day's
/// total, and the current streak), with "Go again" and "Done".
struct SessionCompleteView: View {
    @Environment(\.palette) private var palette
    @Environment(SessionController.self) private var controller
    @Query(sort: \Session.startDate, order: .reverse) private var sessions: [Session]

    var onAgain: () -> Void = {}
    var onDone: () -> Void = {}

    @State private var ringExpand = false

    var body: some View {
        let completed = controller.completed
        let mode = completed?.mode ?? .listening
        let dark = palette.isDark

        let agg = SessionAggregator(sessions: sessions.map(\.snapshot), now: Date())
        let today = agg.totalsByMode(onDayStarting: Calendar.current.startOfDay(for: Date()))

        ZStack {
            palette.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                badge(mode: mode)
                Text("SESSION SAVED")
                    .font(.barlow(13, .bold)).tracking(1.4)
                    .foregroundStyle(palette.faint)
                    .padding(.top, 26)
                Text(TrakiFormat.duration(completed?.seconds ?? 0))
                    .font(.barlowSemi(72, .heavy)).monospacedDigit()
                    .foregroundStyle(palette.text)
                    .padding(.top, 8)
                Text(mode.displayName)
                    .font(.barlow(17, .semibold))
                    .foregroundStyle(palette.muted)
                    .padding(.top, 6)

                HStack(spacing: 12) {
                    statCard(TrakiFormat.duration(today[mode] ?? 0), "\(mode.displayName) today",
                             color: mode.ink(dark: dark))
                    statCard(TrakiFormat.duration(today.values.reduce(0, +)), "Total today",
                             color: palette.text)
                    statCard("\(agg.currentStreak())", "day streak",
                             color: LearningMode.flashcards.ink(dark: dark))
                }
                .padding(.top, 40)

                Spacer(minLength: 0)
                buttons
            }
            .padding(.horizontal, 26)
            .padding(.top, 110)
            .padding(.bottom, 40)
        }
        .onAppear { ringExpand = true }
    }

    private func badge(mode: LearningMode) -> some View {
        ZStack {
            Circle()
                .stroke(mode.baseColor, lineWidth: 3)
                .scaleEffect(ringExpand ? 1.9 : 0.96)
                .opacity(ringExpand ? 0 : 0.55)
                .animation(.easeOut(duration: 1.8).repeatForever(autoreverses: false), value: ringExpand)
            Circle()
                .fill(mode.baseColor)
                .overlay(
                    Image(systemName: "checkmark")
                        .font(.system(size: 40, weight: .heavy))
                        .foregroundStyle(.white)
                )
        }
        .frame(width: 96, height: 96)
    }

    private func statCard(_ value: String, _ label: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.barlowSemi(26, .heavy)).monospacedDigit()
                .foregroundStyle(color)
                .lineLimit(1).minimumScaleFactor(0.6)
            Text(label)
                .font(.barlow(12.5, .regular))
                .foregroundStyle(palette.faint)
                .lineLimit(1).minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 16)
        .padding(.horizontal, 14)
        .background(palette.panel, in: .rect(cornerRadius: 18, style: .continuous))
        .shadow(color: palette.panelShadow.color, radius: palette.panelShadow.radius,
                y: palette.panelShadow.y)
    }

    private var buttons: some View {
        HStack(spacing: 14) {
            Button(action: onAgain) {
                Text("Go again")
                    .font(.barlow(16, .bold))
                    .foregroundStyle(palette.text)
                    .frame(maxWidth: .infinity).frame(height: 60)
                    .background(palette.track, in: .rect(cornerRadius: 19, style: .continuous))
            }
            .buttonStyle(.plain)

            Button(action: onDone) {
                Text("Done")
                    .font(.barlow(16, .heavy))
                    .foregroundStyle(palette.bg)
                    .frame(maxWidth: .infinity).frame(height: 60)
                    .background(palette.text, in: .rect(cornerRadius: 19, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("done")
        }
    }
}

#Preview {
    let controller = SessionController()
    controller.start(.reading)
    _ = controller.stop()
    let container = TrakiStore.makeContainer(inMemory: true)
    SampleData.seedIfEmpty(container.mainContext)
    return SessionCompleteView()
        .environment(controller)
        .environment(\.palette, .light)
        .modelContainer(container)
}
