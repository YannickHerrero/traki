import SwiftData
import SwiftUI
import TrakiKit
import WidgetKit

/// The bottom sheet for logging a past session or editing an existing one:
/// pick a mode, choose Today/Yesterday (new only), set a duration with −/+ or a
/// quick-pick, then save (or delete, when editing).
struct LogSheetView: View {
    @Environment(\.palette) private var palette
    @Environment(AppSettings.self) private var settings
    @Environment(\.modelContext) private var modelContext
    @Bindable var controller: LogSheetController

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            handle
            headerRow

            sectionLabel("Mode")
            modeChips.padding(.bottom, 22)

            whenRow.padding(.bottom, 20)

            sectionLabel("Duration")
            durationStepper.padding(.top, 12).padding(.bottom, 14)
            quickPicks.padding(.bottom, 24)

            saveButton
            if controller.isEditing { deleteButton.padding(.top, 10) }
        }
        .padding(.horizontal, 22)
        .padding(.top, 10)
        .padding(.bottom, 34)
        .frame(maxWidth: .infinity, alignment: .leading)
        .presentationDetents([.fraction(controller.isEditing ? 0.82 : 0.74)])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(28)
        .presentationBackground(palette.bg)
    }

    // MARK: Header

    private var handle: some View {
        Capsule()
            .fill(palette.track)
            .frame(width: 40, height: 5)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 18)
    }

    private var headerRow: some View {
        HStack {
            Text(controller.isEditing ? "Edit session" : "Log a session")
                .font(.barlowSemi(24, .heavy))
                .foregroundStyle(palette.text)
            Spacer()
            Button { controller.isPresented = false } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(palette.muted)
                    .frame(width: 32, height: 32)
                    .background(palette.chip, in: .circle)
            }
            .buttonStyle(.plain)
        }
        .padding(.bottom, 20)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.barlow(12, .bold)).tracking(0.6)
            .foregroundStyle(palette.faint)
            .padding(.bottom, controller.isEditing ? 10 : 10)
    }

    // MARK: Mode chips

    private var modeChips: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 9),
                            GridItem(.flexible(), spacing: 9)], spacing: 9) {
            ForEach(settings.orderedActiveModes) { mode in
                let selected = controller.mode == mode
                Button { controller.mode = mode } label: {
                    Text(mode.displayName)
                        .font(.nunito(15, .heavy))
                        .foregroundStyle(selected ? mode.ink(dark: palette.isDark) : palette.muted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(1).minimumScaleFactor(0.8)
                        .padding(14)
                        .background(selected ? mode.baseColor.opacity(0.15) : palette.chip,
                                    in: .rect(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(selected ? mode.baseColor : palette.hair,
                                              lineWidth: selected ? 1.5 : 1))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("logchip-\(mode.rawValue)")
            }
        }
    }

    // MARK: When

    @ViewBuilder private var whenRow: some View {
        if controller.isEditing {
            HStack {
                Text("WHEN").font(.barlow(12, .bold)).tracking(0.6).foregroundStyle(palette.faint)
                Spacer()
                Text(editDayLabel).font(.barlow(14, .bold)).foregroundStyle(palette.muted)
            }
        } else {
            HStack {
                Text("WHEN").font(.barlow(12, .bold)).tracking(0.6).foregroundStyle(palette.faint)
                Spacer()
                HStack(spacing: 3) {
                    daySegment("Today", selected: !controller.isYesterday) { controller.isYesterday = false }
                    daySegment("Yesterday", selected: controller.isYesterday) { controller.isYesterday = true }
                }
                .padding(3)
                .background(palette.track, in: .rect(cornerRadius: 11, style: .continuous))
            }
        }
    }

    private func daySegment(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.barlow(13, .bold))
                .foregroundStyle(selected ? palette.bg : palette.faint)
                .padding(.vertical, 6).padding(.horizontal, 16)
                .background(selected ? palette.text : .clear, in: .rect(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var editDayLabel: String {
        guard let start = controller.editing?.startDate else { return "" }
        let cal = Calendar.current
        if cal.isDateInToday(start) { return "Today" }
        if cal.isDateInYesterday(start) { return "Yesterday" }
        return start.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }

    // MARK: Duration

    private var durationStepper: some View {
        HStack(spacing: 20) {
            stepButton("minus") { controller.setMinutes(controller.minutes - 5) }
            Text("\(controller.minutes) min")
                .font(.barlowSemi(40, .heavy)).monospacedDigit()
                .foregroundStyle(palette.text)
                .frame(minWidth: 130)
                .multilineTextAlignment(.center)
            stepButton("plus") { controller.setMinutes(controller.minutes + 5) }
        }
        .frame(maxWidth: .infinity)
    }

    private func stepButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(palette.text)
                .frame(width: 48, height: 48)
                .background(palette.chip, in: .circle)
                .overlay(Circle().strokeBorder(palette.hair, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var quickPicks: some View {
        HStack(spacing: 8) {
            ForEach([15, 30, 45, 60], id: \.self) { value in
                let selected = controller.minutes == value
                Button { controller.setMinutes(value) } label: {
                    Text("\(value)m")
                        .font(.barlow(14, .bold))
                        .foregroundStyle(selected ? palette.bg : palette.muted)
                        .padding(.vertical, 8).padding(.horizontal, 18)
                        .background(selected ? palette.text : palette.chip, in: .capsule)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("quick-\(value)")
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Save / delete

    private var saveButton: some View {
        Button { save() } label: {
            Text(saveLabel)
                .font(.barlow(16, .heavy))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity).frame(height: 56)
                .background(controller.mode.baseColor, in: .rect(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("log-save")
    }

    private var saveLabel: String {
        controller.isEditing
            ? "Save changes"
            : "Add \(controller.minutes) min to \(controller.mode.displayName)"
    }

    private var deleteButton: some View {
        Button { deleteEntry() } label: {
            Text("Delete entry")
                .font(.barlow(15, .bold))
                .foregroundStyle(Color(hex: "E5484D"))
                .frame(maxWidth: .infinity).frame(height: 50)
                .background(Color(hex: "E5484D").opacity(0.1), in: .rect(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("log-delete")
    }

    // MARK: Actions

    private func save() {
        if let editing = controller.editing {
            editing.mode = controller.mode
            editing.durationSeconds = controller.minutes * 60
            try? modelContext.save()
        } else {
            let calendar = Calendar.current
            let now = Date()
            let start: Date
            if controller.isYesterday {
                let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
                start = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: yesterday) ?? yesterday
            } else {
                // A "today" entry ends now, so it reads as a recent past session.
                start = now.addingTimeInterval(-Double(controller.minutes * 60))
            }
            modelContext.insert(Session(mode: controller.mode, startDate: start,
                                        durationSeconds: controller.minutes * 60, isManual: true))
            try? modelContext.save()
        }
        WidgetCenter.shared.reloadAllTimelines()
        controller.isPresented = false
    }

    private func deleteEntry() {
        if let editing = controller.editing {
            modelContext.delete(editing)
            try? modelContext.save()
        }
        WidgetCenter.shared.reloadAllTimelines()
        controller.isPresented = false
    }
}
