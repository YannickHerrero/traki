import SwiftData
import SwiftUI
import TrakiKit

/// A calm, full-screen view for a session in progress, tinted with the mode's
/// color. Shows a live clock and a running projection of today's total for the
/// mode, with pause/resume and stop-and-save controls.
struct ActiveTimerView: View {
    @Environment(\.palette) private var palette
    @Environment(SessionController.self) private var controller
    @Environment(TimerPictureInPictureController.self) private var pictureInPicture
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Query(sort: \Session.startDate, order: .reverse) private var sessions: [Session]

    /// Persist-and-complete, supplied by the root coordinator (Phase 6).
    var onStop: () -> Void = {}

    @State private var pulsing = false

    var body: some View {
        let mode = controller.mode ?? .listening
        let dark = palette.isDark
        let earlierToday = todaySeconds(for: mode)

        ZStack {
            background(mode: mode, dark: dark)

            VStack(alignment: .leading, spacing: 0) {
                statusRow(mode: mode)
                modeRow(mode: mode, earlierToday: earlierToday)

                Spacer(minLength: 0)
                clockBlock(mode: mode, dark: dark, earlierToday: earlierToday)
                Spacer(minLength: 0)

                controls(mode: mode)
            }
            .padding(.horizontal, 26)
            .padding(.top, 96)
            .padding(.bottom, 42)
            .frame(maxWidth: horizontalSizeClass == .regular ? 760 : .infinity)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear { pulsing = true }
        .alert("Picture in Picture unavailable",
               isPresented: Binding(get: { pictureInPicture.errorMessage != nil },
                                    set: { if !$0 { pictureInPicture.dismissError() } })) {
            Button("OK", role: .cancel) { pictureInPicture.dismissError() }
        } message: {
            Text(pictureInPicture.errorMessage ?? "Picture in Picture could not start.")
        }
    }

    // MARK: Pieces

    private func background(mode: LearningMode, dark: Bool) -> some View {
        ZStack {
            palette.bg
            RadialGradient(
                gradient: Gradient(colors: [mode.baseColor.opacity(dark ? 0.22 : 0.26), .clear]),
                center: UnitPoint(x: 0.5, y: 0.0), startRadius: 0, endRadius: 460)
        }
        .ignoresSafeArea()
    }

    private func statusRow(mode: LearningMode) -> some View {
        HStack(spacing: 9) {
            Circle()
                .fill(mode.baseColor)
                .frame(width: 9, height: 9)
                .opacity(controller.isRunning ? (reduceMotion ? 1 : (pulsing ? 1 : 0.3)) : 0.5)
                .animation(controller.isRunning && !reduceMotion
                           ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true)
                           : .default, value: pulsing)
            Text(controller.isRunning ? "TRACKING" : "PAUSED")
                .font(.barlow(13, .bold))
                .tracking(1.4)
                .foregroundStyle(palette.muted)
            Spacer()
            Button(action: pictureInPicture.start) {
                Image(systemName: "pip.enter")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(palette.text)
                    .frame(width: 44, height: 44)
                    .background(palette.track, in: .circle)
            }
            .buttonStyle(.plain)
            .disabled(!pictureInPicture.canStart)
            .accessibilityIdentifier("timer-pip")
            .accessibilityLabel("Start Picture in Picture")
            .accessibilityHint(!pictureInPicture.isSupported
                               ? "Picture in Picture is unavailable on this device"
                               : pictureInPicture.isPossible
                               ? "Shows the timer in a floating window"
                               : "Picture in Picture is preparing")
        }
    }

    private func modeRow(mode: LearningMode, earlierToday: Int) -> some View {
        HStack(spacing: 13) {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(mode.baseColor.opacity(0.28))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: mode.symbolName)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(mode.ink(dark: palette.isDark))
                )
            VStack(alignment: .leading, spacing: 3) {
                Text(mode.displayName)
                    .font(.barlowSemi(26, .heavy))
                    .foregroundStyle(palette.text)
                Text("\(TrakiFormat.duration(earlierToday)) logged earlier today")
                    .font(.barlow(13.5, .regular))
                    .foregroundStyle(palette.faint)
            }
        }
        .padding(.top, 30)
    }

    private func clockBlock(mode: LearningMode, dark: Bool, earlierToday: Int) -> some View {
        TimelineView(.periodic(from: .now, by: 0.5)) { context in
            let elapsed = controller.elapsed(at: context.date)
            VStack(spacing: 14) {
                Text(TrakiFormat.clock(elapsed))
                    .font(.barlowSemi(96, .heavy))
                    .tracking(-2)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .foregroundStyle(mode.ink(dark: dark))
                    .accessibilityLabel("Elapsed \(TrakiFormat.duration(elapsed))")
                Text("reaches ")
                    .font(.barlow(14, .regular))
                    .foregroundStyle(palette.faint)
                + Text(TrakiFormat.duration(Double(earlierToday) + elapsed))
                    .font(.barlow(14, .bold))
                    .foregroundStyle(palette.text)
                + Text(" today")
                    .font(.barlow(14, .regular))
                    .foregroundStyle(palette.faint)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func controls(mode: LearningMode) -> some View {
        HStack(spacing: 14) {
            Button {
                controller.togglePause()
            } label: {
                Text(controller.isRunning ? "Pause" : "Resume")
                    .font(.barlow(17, .bold))
                    .foregroundStyle(palette.text)
                    .frame(maxWidth: .infinity)
                    .frame(height: 64)
                    .background(palette.track, in: .rect(cornerRadius: 20, style: .continuous))
            }
            .buttonStyle(.plain)

            Button {
                onStop()
            } label: {
                HStack(spacing: 9) {
                    RoundedRectangle(cornerRadius: 3).fill(.white).frame(width: 14, height: 14)
                    Text("Stop & save")
                        .font(.barlow(17, .heavy))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .background(mode.baseColor, in: .rect(cornerRadius: 20, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("stop-save")
        }
    }

    // MARK: Data

    private func todaySeconds(for mode: LearningMode) -> Int {
        let agg = SessionAggregator(sessions: sessions.map(\.snapshot), now: Date())
        return agg.totalsByMode(onDayStarting: Calendar.current.startOfDay(for: Date()))[mode] ?? 0
    }
}

#Preview {
    let controller = SessionController()
    controller.start(.listening)
    let container = TrakiStore.makeContainer(inMemory: true)
    SampleData.seedIfEmpty(container.mainContext)
    return ActiveTimerView()
        .environment(controller)
        .environment(TimerPictureInPictureController(sessionController: controller))
        .environment(\.palette, .dark)
        .modelContainer(container)
}
