import SwiftUI
import TrakiKit

/// Settings — the small set of choices that personalise tracking: Learning,
/// Appearance and Tracking.
struct SettingsScreen: View {
    @Environment(\.palette) private var palette
    @Environment(AppSettings.self) private var settings
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var showCategories = false

    private let languages = ["Japanese", "Korean", "Mandarin", "Spanish",
                             "French", "German", "Italian", "English"]
    private let goalOptions = Array(stride(from: 30, through: 300, by: 15))

    var body: some View {
        @Bindable var settings = settings

        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("Settings")
                    .font(.barlowSemi(30, .heavy))
                    .foregroundStyle(palette.text)

                if horizontalSizeClass == .regular {
                    HStack(alignment: .top, spacing: 18) {
                        learningSection(settings).frame(maxWidth: .infinity, alignment: .topLeading)
                        appearanceSection(settings).frame(maxWidth: .infinity, alignment: .topLeading)
                    }
                } else {
                    learningSection(settings)
                    appearanceSection(settings)
                }
                trackingSection(settings)

                Text("Traki · v\(TrakiKit.version)")
                    .font(.barlow(12, .regular))
                    .foregroundStyle(palette.dim)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .sheet(isPresented: $showCategories) {
            CategoriesSheet(settings: settings)
        }
    }

    // MARK: Learning

    private func learningSection(_ settings: AppSettings) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Learning")
            card {
                row(icon: "globe", tint: LearningMode.sentenceMining.baseColor, title: "Language") {
                    Menu {
                        ForEach(languages, id: \.self) { language in
                            Button(language) { settings.language = language }
                        }
                    } label: {
                        valueChevron(settings.language)
                    }
                }
                separator
                row(icon: "target", tint: LearningMode.reading.baseColor, title: "Daily goal") {
                    Menu {
                        ForEach(goalOptions, id: \.self) { minutes in
                            Button(goalLabel(minutes)) { settings.dailyGoalMinutes = minutes }
                        }
                    } label: {
                        valueChevron(goalLabel(settings.dailyGoalMinutes))
                    }
                }
                separator
                Button { showCategories = true } label: {
                    row(icon: "square.grid.2x2.fill", tint: LearningMode.flashcards.baseColor,
                        title: "Categories") {
                        valueChevron("\(settings.activeModes.count) active")
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func goalLabel(_ minutes: Int) -> String {
        minutes >= 60 ? TrakiFormat.duration(minutes * 60) : "\(minutes)m"
    }

    // MARK: Appearance

    private func appearanceSection(_ settings: AppSettings) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Appearance")
            card {
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(LearningMode.listening.baseColor)
                        .frame(width: 28, height: 28)
                        .overlay(Image(systemName: "paintbrush.fill")
                            .font(.system(size: 13, weight: .bold)).foregroundStyle(.white))
                    Text("Theme").font(.barlow(16, .regular)).foregroundStyle(palette.text)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 4)

                HStack(spacing: 6) {
                    ForEach(AppTheme.allCases) { option in
                        let selected = settings.theme == option
                        Button { settings.theme = option } label: {
                            Text(option.label)
                                .font(.nunito(14, .heavy))
                                .foregroundStyle(selected ? .white : palette.muted)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(selected ? LearningMode.listening.baseColor : palette.track,
                                            in: .rect(cornerRadius: 11, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("theme-\(option.rawValue)")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
    }

    // MARK: Tracking

    private func trackingSection(_ settings: AppSettings) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Tracking")
            card {
                toggleRow("Auto-pause when idle",
                          Binding(get: { settings.autoPauseWhenIdle },
                                  set: { settings.autoPauseWhenIdle = $0 }))
                separator
                toggleRow("Live Activity on Lock Screen",
                          Binding(get: { settings.showLiveActivity },
                                  set: { settings.showLiveActivity = $0 }))
                separator
                toggleRow("Round sessions to the nearest minute",
                          Binding(get: { settings.roundToNearestMinute },
                                  set: { settings.roundToNearestMinute = $0 }))
            }
        }
    }

    private func toggleRow(_ title: String, _ isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            Text(title).font(.barlow(16, .regular)).foregroundStyle(palette.text)
            Spacer()
            Toggle("", isOn: isOn).labelsHidden().tint(LearningMode.reading.baseColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: Building blocks

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.barlow(12, .bold)).tracking(1)
            .foregroundStyle(palette.faint)
            .padding(.horizontal, 6)
    }

    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(spacing: 0) { content() }
            .background(palette.panel, in: .rect(cornerRadius: 18, style: .continuous))
            .shadow(color: palette.panelShadow.color, radius: palette.panelShadow.radius,
                    y: palette.panelShadow.y)
    }

    private func row<Trailing: View>(icon: String, tint: Color, title: String,
                                     @ViewBuilder trailing: () -> Trailing) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(tint)
                .frame(width: 28, height: 28)
                .overlay(Image(systemName: icon).font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white))
            Text(title).font(.barlow(16, .regular)).foregroundStyle(palette.text)
            Spacer()
            trailing()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(.rect)
    }

    private func valueChevron(_ value: String) -> some View {
        HStack(spacing: 4) {
            Text(value)
            Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold))
        }
        .font(.barlow(15, .regular))
        .foregroundStyle(palette.faint)
    }

    private var separator: some View {
        palette.hair.frame(height: 1).padding(.leading, 16)
    }
}

/// A small sheet of per-mode toggles for which categories are active.
private struct CategoriesSheet: View {
    @Environment(\.palette) private var palette
    @Bindable var settings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Capsule().fill(palette.track).frame(width: 40, height: 5)
                .frame(maxWidth: .infinity).padding(.top, 10).padding(.bottom, 18)
            Text("Categories")
                .font(.barlowSemi(24, .heavy)).foregroundStyle(palette.text)
                .padding(.bottom, 4)
            Text("Choose which modes appear on Home.")
                .font(.barlow(13, .regular)).foregroundStyle(palette.faint)
                .padding(.bottom, 18)

            VStack(spacing: 0) {
                ForEach(Array(LearningMode.allCases.enumerated()), id: \.element) { index, mode in
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 7).fill(mode.baseColor).frame(width: 24, height: 24)
                        Text(mode.displayName).font(.barlow(16, .regular)).foregroundStyle(palette.text)
                        Spacer()
                        Toggle("", isOn: binding(for: mode)).labelsHidden().tint(LearningMode.reading.baseColor)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 14)
                    if index < LearningMode.allCases.count - 1 { palette.hair.frame(height: 1).padding(.leading, 16) }
                }
            }
            .background(palette.panel, in: .rect(cornerRadius: 18, style: .continuous))

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .presentationDetents([.height(360)])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(28)
        .presentationBackground(palette.bg)
    }

    /// Keeps at least one mode active.
    private func binding(for mode: LearningMode) -> Binding<Bool> {
        Binding(
            get: { settings.activeModes.contains(mode) },
            set: { isOn in
                if isOn {
                    settings.activeModes.insert(mode)
                } else if settings.activeModes.count > 1 {
                    settings.activeModes.remove(mode)
                }
            })
    }
}

#Preview {
    SettingsScreen()
        .environment(AppSettings())
        .environment(\.palette, .light)
}
