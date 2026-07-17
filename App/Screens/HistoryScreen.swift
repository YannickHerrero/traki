import SwiftData
import SwiftUI
import TrakiKit

/// The complete, trustworthy record of every session, grouped by day
/// (newest-first) with each day's total. Hold an entry to edit or delete it.
struct HistoryScreen: View {
    @Environment(\.palette) private var palette
    @Environment(LogSheetController.self) private var logSheet
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Query(sort: \Session.startDate, order: .reverse) private var sessions: [Session]

    var body: some View {
        let days = SessionAggregator(sessions: sessions.map(\.snapshot), now: Date()).historyDays()

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("History")
                    .font(.barlowSemi(30, .heavy))
                    .foregroundStyle(palette.text)
                Text("Hold an entry to edit or delete it.")
                    .font(.barlow(12.5, .regular))
                    .foregroundStyle(palette.faint)
                    .padding(.top, 2)
                    .padding(.bottom, 18)

                if horizontalSizeClass == .regular {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 18),
                                        GridItem(.flexible(), spacing: 18)],
                              alignment: .leading, spacing: 0) {
                        ForEach(days) { day in
                            dayGroup(day)
                        }
                    }
                } else {
                    ForEach(days) { day in
                        dayGroup(day)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
    }

    private func dayGroup(_ day: HistoryDay) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(dayLabel(day.date))
                    .font(.barlow(13, .bold)).tracking(0.4)
                    .foregroundStyle(palette.muted)
                Spacer()
                Text(TrakiFormat.duration(day.total))
                    .font(.barlow(13, .bold)).monospacedDigit()
                    .foregroundStyle(palette.faint)
            }

            VStack(spacing: 0) {
                ForEach(Array(day.entries.enumerated()), id: \.element.id) { index, entry in
                    entryRow(entry)
                        .onLongPressGesture(minimumDuration: 0.48) { edit(entry) }
                    if index < day.entries.count - 1 {
                        palette.hair.frame(height: 1)
                    }
                }
            }
            .background(palette.panel, in: .rect(cornerRadius: 18, style: .continuous))
            .shadow(color: palette.panelShadow.color, radius: palette.panelShadow.radius,
                    y: palette.panelShadow.y)
        }
        .padding(.bottom, 22)
    }

    private func entryRow(_ entry: HistoryEntry) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 3)
                .fill(entry.mode.baseColor)
                .frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 1) {
                Text(entry.mode.displayName)
                    .font(.barlow(15, .semibold))
                    .foregroundStyle(palette.text)
                Text(rangeLabel(entry))
                    .font(.barlow(12, .regular)).monospacedDigit()
                    .foregroundStyle(palette.faint)
            }
            Spacer()
            Text(TrakiFormat.duration(entry.seconds))
                .font(.barlow(15, .bold)).monospacedDigit()
                .foregroundStyle(palette.muted)
        }
        .padding(.vertical, 13)
        .padding(.horizontal, 15)
        .contentShape(.rect)
    }

    /// Opens the edit sheet for the tapped entry's underlying session.
    private func edit(_ entry: HistoryEntry) {
        guard let session = sessions.first(where: { $0.id == entry.id }) else { return }
        logSheet.openEdit(session)
    }

    // MARK: Formatting

    private func dayLabel(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        return date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
    }

    private func rangeLabel(_ entry: HistoryEntry) -> String {
        let end = entry.start.addingTimeInterval(Double(entry.seconds))
        let start = entry.start.formatted(date: .omitted, time: .shortened)
        let finish = end.formatted(date: .omitted, time: .shortened)
        return "\(start) – \(finish)"
    }
}

#Preview {
    let container = TrakiStore.makeContainer(inMemory: true)
    SampleData.seedIfEmpty(container.mainContext)
    return HistoryScreen()
        .environment(LogSheetController())
        .environment(\.palette, .light)
        .modelContainer(container)
}
