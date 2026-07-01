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
