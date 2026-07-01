import SwiftData
import SwiftUI
import TrakiKit

/// Statistics — helps learners understand their habits and see progress build.
/// A Day/Month/Year switch drives the total, its change vs. the previous period,
/// and the charts below.
struct StatsScreen: View {
    @Environment(\.palette) private var palette
    @Query(sort: \Session.startDate, order: .reverse) private var sessions: [Session]
    @State private var period: StatsPeriod = .day

    var body: some View {
        let agg = SessionAggregator(sessions: sessions.map(\.snapshot), now: Date())
        let stats = agg.periodStats(period)

        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Statistics")
                    .font(.barlowSemi(30, .heavy))
                    .foregroundStyle(palette.text)

                periodPicker
                totalHeader(stats)
                last7DaysCard(agg.lastDays(7))
                breakdownCard(agg.breakdown(period))
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
    }

    private var periodPicker: some View {
        HStack(spacing: 0) {
            ForEach(StatsPeriod.allCases) { option in
                let selected = period == option
                Button { period = option } label: {
                    Text(option.rawValue)
                        .font(.barlow(14, .bold))
                        .foregroundStyle(selected ? palette.bg : palette.faint)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(selected ? palette.text : .clear,
                                    in: .rect(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(palette.track, in: .rect(cornerRadius: 13, style: .continuous))
    }

    // MARK: Last 7 days

    private func last7DaysCard(_ days: [DayBucket]) -> some View {
        let maxTotal = Double(max(1, days.map(\.total).max() ?? 1))
        let columnHeight = 118.0
        return statCard("Last 7 days") {
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(days) { day in
                    let today = Calendar.current.isDateInToday(day.date)
                    VStack(spacing: 7) {
                        ZStack(alignment: .bottom) {
                            Color.clear.frame(height: columnHeight)
                            VStack(spacing: 0) {
                                // Reversed so Flashcards sits at the bottom of the stack.
                                ForEach(LearningMode.allCases.reversed()) { mode in
                                    Rectangle()
                                        .fill(mode.baseColor.opacity(today ? 1 : 0.82))
                                        .frame(height: Double(day.seconds(mode)) / maxTotal * columnHeight)
                                }
                            }
                            .frame(width: 26)
                            .clipShape(.rect(cornerRadius: 6))
                        }
                        Text(day.date.formatted(.dateTime.weekday(.narrow)))
                            .font(.barlow(11, .semibold))
                            .foregroundStyle(today ? palette.text : palette.faint)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    // MARK: By category

    private func breakdownCard(_ items: [ModeBreakdownItem]) -> some View {
        let maxSeconds = Double(max(1, items.map(\.seconds).max() ?? 1))
        return statCard("By category") {
            VStack(spacing: 14) {
                ForEach(items) { item in
                    VStack(spacing: 6) {
                        HStack {
                            Text(item.mode.displayName)
                                .font(.barlow(14, .semibold))
                                .foregroundStyle(item.mode.ink(dark: palette.isDark))
                            Spacer()
                            Text(TrakiFormat.duration(item.seconds))
                                .font(.barlow(14, .bold)).monospacedDigit()
                                .foregroundStyle(palette.muted)
                        }
                        GeometryReader { geo in
                            let fraction = item.seconds == 0 ? 0 : max(0.03, Double(item.seconds) / maxSeconds)
                            ZStack(alignment: .leading) {
                                Capsule().fill(palette.track)
                                Capsule().fill(item.mode.baseColor)
                                    .frame(width: geo.size.width * fraction)
                            }
                        }
                        .frame(height: 9)
                    }
                }
            }
        }
    }

    // MARK: Shared card

    private func statCard<Content: View>(_ title: String,
                                         @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.barlow(13, .bold))
                .foregroundStyle(palette.muted)
                .padding(.bottom, 16)
            content()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.panel, in: .rect(cornerRadius: 22, style: .continuous))
        .shadow(color: palette.panelShadow.color, radius: palette.panelShadow.radius,
                y: palette.panelShadow.y)
    }

    private func totalHeader(_ stats: PeriodStats) -> some View {
        HStack(alignment: .bottom, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(period.totalLabel) total".uppercased())
                    .font(.barlow(12.5, .regular)).tracking(0.5)
                    .foregroundStyle(palette.faint)
                Text(TrakiFormat.duration(stats.total))
                    .font(.barlowSemi(52, .heavy)).monospacedDigit()
                    .foregroundStyle(palette.text)
            }
            if let delta = stats.deltaPercent {
                HStack(spacing: 5) {
                    Image(systemName: delta >= 0 ? "arrow.up" : "arrow.down")
                    Text("\(abs(delta))%").monospacedDigit()
                }
                .font(.barlow(15, .bold))
                .foregroundStyle(delta >= 0 ? Color(hex: "1FA07C") : Color(hex: "E5484D"))
                .padding(.bottom, 8)
            }
            Spacer(minLength: 0)
        }
    }
}

#Preview {
    let container = TrakiStore.makeContainer(inMemory: true)
    SampleData.seedIfEmpty(container.mainContext)
    return StatsScreen()
        .environment(\.palette, .light)
        .modelContainer(container)
}
