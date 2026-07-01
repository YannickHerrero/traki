import ActivityKit
import SwiftUI
import TrakiKit
import WidgetKit

/// The running-session Live Activity: a Lock-Screen banner and Dynamic Island,
/// both driven by `TrakiActivityAttributes.ContentState`. The clock ticks on its
/// own via `Text(timerInterval:)`, so it stays live without app updates.
struct TrakiLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TrakiActivityAttributes.self) { context in
            LiveActivityLockScreenView(state: context.state)
                .activityBackgroundTint(Color.black.opacity(0.5))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            let mode = context.state.mode
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(mode.displayName, systemImage: mode.symbolName)
                        .foregroundStyle(mode.baseColor)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    liveClock(context.state).foregroundStyle(mode.baseColor)
                }
            } compactLeading: {
                Image(systemName: mode.symbolName).foregroundStyle(mode.baseColor)
            } compactTrailing: {
                liveClock(context.state).foregroundStyle(mode.baseColor)
            } minimal: {
                Image(systemName: mode.symbolName).foregroundStyle(mode.baseColor)
            }
            .keylineTint(mode.baseColor)
        }
    }
}

/// The Lock-Screen banner.
struct LiveActivityLockScreenView: View {
    let state: TrakiActivityAttributes.ContentState

    var body: some View {
        let mode = state.mode
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(mode.baseColor.opacity(0.22))
                .frame(width: 46, height: 46)
                .overlay(Image(systemName: mode.symbolName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(mode.baseColor))
            VStack(alignment: .leading, spacing: 2) {
                Text("\(mode.displayName) · \(state.isRunning ? "running" : "paused")")
                    .font(.barlow(12.5, .semibold))
                    .foregroundStyle(.white.opacity(0.6))
                liveClock(state)
                    .font(.barlowSemi(26, .heavy))
                    .foregroundStyle(mode.baseColor)
            }
            Spacer(minLength: 0)
            if state.isRunning {
                Circle().fill(mode.baseColor).frame(width: 10, height: 10)
            }
        }
        .padding(16)
    }
}

/// A live-ticking clock while running, or the frozen elapsed while paused.
@ViewBuilder
func liveClock(_ state: TrakiActivityAttributes.ContentState) -> some View {
    if state.isRunning {
        Text(timerInterval: state.effectiveStart...Date.distantFuture, countsDown: false)
            .monospacedDigit()
    } else {
        Text(TrakiFormat.clock(state.frozenElapsed))
            .monospacedDigit()
    }
}
