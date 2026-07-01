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
                trendCard(agg.weeklyTrend(weeks: 8))
                heatmapCard(agg.heatmap(days: 112))
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

    // MARK: Consistency heatmap

    private func heatmapCard(_ cells: [HeatCell]) -> some View {
        panel {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Consistency")
                        .font(.barlow(13, .bold)).foregroundStyle(palette.muted)
                    Spacer()
                    legend
                }
                .padding(.bottom, 14)

                // Column-major: 7 rows (weekday) × 16 columns (week), today bottom-right.
                Grid(horizontalSpacing: 4, verticalSpacing: 4) {
                    ForEach(0..<7, id: \.self) { row in
                        GridRow {
                            ForEach(Array(stride(from: row, to: cells.count, by: 7)), id: \.self) { index in
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(heatColor(cells[index].level))
                                    .aspectRatio(1, contentMode: .fit)
                            }
                        }
                    }
                }
            }
        }
    }

    private var legend: some View {
        HStack(spacing: 5) {
            Text("less").font(.barlow(11, .regular)).foregroundStyle(palette.faint)
            ForEach([0, 2, 3, 4], id: \.self) { level in
                RoundedRectangle(cornerRadius: 3)
                    .fill(heatColor(level))
                    .frame(width: 10, height: 10)
            }
            Text("more").font(.barlow(11, .regular)).foregroundStyle(palette.faint)
        }
    }

    private func heatColor(_ level: Int) -> Color {
        let green = LearningMode.reading.baseColor
        switch level {
        case 0: return palette.track
        case 1: return green.opacity(0.35)
        case 2: return green.opacity(0.55)
        case 3: return green.opacity(0.75)
        default: return green.opacity(0.95)
        }
    }

    // MARK: Trend

    private func trendCard(_ weekly: [Double]) -> some View {
        panel {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Trend · daily hours")
                        .font(.barlow(13, .bold)).foregroundStyle(palette.muted)
                    Spacer()
                    Text("8 weeks")
                        .font(.barlow(12, .regular)).foregroundStyle(palette.faint)
                }
                .padding(.bottom, 12)
                TrendLine(values: weekly, color: LearningMode.reading.baseColor)
                    .frame(height: 110)
            }
        }
    }

    // MARK: Shared card

    private func statCard<Content: View>(_ title: String,
                                         @ViewBuilder content: () -> Content) -> some View {
        panel {
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.barlow(13, .bold))
                    .foregroundStyle(palette.muted)
                    .padding(.bottom, 16)
                content()
            }
        }
    }

    private func panel<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
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

/// The daily-hours trend: a filled area under a smooth stroked line, scaled to
/// the card width, mirroring the prototype's SVG polyline math.
private struct TrendLine: View {
    let values: [Double]
    let color: Color

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let padX = 8.0, padY = 14.0
            let maxValue = values.max() ?? 1
            let minValue = values.min() ?? 0
            let span = maxValue - minValue

            let points: [CGPoint] = values.indices.map { i in
                let x = padX + Double(i) / Double(max(1, values.count - 1)) * (width - 2 * padX)
                let y = span == 0 ? height / 2
                    : height - padY - (values[i] - minValue) / span * (height - 2 * padY)
                return CGPoint(x: x, y: y)
            }

            ZStack {
                Path { path in
                    guard let first = points.first, let last = points.last else { return }
                    path.move(to: CGPoint(x: first.x, y: height))
                    points.forEach { path.addLine(to: $0) }
                    path.addLine(to: CGPoint(x: last.x, y: height))
                    path.closeSubpath()
                }
                .fill(LinearGradient(colors: [color.opacity(0.28), color.opacity(0)],
                                     startPoint: .top, endPoint: .bottom))

                Path { path in
                    guard let first = points.first else { return }
                    path.move(to: first)
                    points.dropFirst().forEach { path.addLine(to: $0) }
                }
                .stroke(color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
            }
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
