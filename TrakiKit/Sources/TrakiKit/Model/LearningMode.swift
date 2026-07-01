import SwiftUI

/// The four study activities Traki tracks. Each keeps a consistent color across
/// the whole app so learners recognise it instantly in cards, charts and history.
///
/// Raw values match the prototype's `catId`s (`flash`/`listen`/`read`/`mine`),
/// which is what gets persisted on each `Session`. `allCases` is in the app's
/// canonical order: Flashcards, Listening, Reading, Sentence Mining.
public enum LearningMode: String, CaseIterable, Identifiable, Codable, Sendable {
    case flashcards = "flash"
    case listening = "listen"
    case reading = "read"
    case sentenceMining = "mine"

    public var id: String { rawValue }

    /// Full name, e.g. "Sentence Mining" (home cards, history, breakdowns).
    public var displayName: String {
        switch self {
        case .flashcards: "Flashcards"
        case .listening: "Listening"
        case .reading: "Reading"
        case .sentenceMining: "Sentence Mining"
        }
    }

    /// Short name for tight spots like Lock-Screen and quick-start widgets.
    public var compactName: String {
        switch self {
        case .flashcards: "Cards"
        case .listening: "Listen"
        case .reading: "Read"
        case .sentenceMining: "Mine"
        }
    }

    /// SF Symbol used where a system glyph is appropriate (settings, widgets).
    /// The home grid uses bespoke shapes that echo the prototype's SVGs.
    public var symbolName: String {
        switch self {
        case .flashcards: "rectangle.on.rectangle.angled"
        case .listening: "waveform"
        case .reading: "book"
        case .sentenceMining: "diamond"
        }
    }

    /// Theme-independent fill (dots, chips, filled buttons, chart bars).
    public var baseColor: Color {
        switch self {
        case .flashcards: Color(hex: "F6A93B")
        case .listening: Color(hex: "B98BFF")
        case .reading: Color(hex: "35D0A5")
        case .sentenceMining: Color(hex: "5AA0FF")
        }
    }

    /// Darker partner used as the second stop of the resume-hero gradient.
    public var gradientPartner: Color {
        switch self {
        case .flashcards: Color(hex: "E08A1E")
        case .listening: Color(hex: "8E5BE0")
        case .reading: Color(hex: "1FA07C")
        case .sentenceMining: Color(hex: "2F79D6")
        }
    }

    /// Legible text tint for the mode's name. Brighter in dark mode, deeper in
    /// light mode, matching the prototype's `flashInk`/`listenInk`/… tokens.
    public func ink(dark: Bool) -> Color {
        switch (self, dark) {
        case (.flashcards, true): Color(hex: "F6A93B")
        case (.flashcards, false): Color(hex: "C77E12")
        case (.listening, true): Color(hex: "B98BFF")
        case (.listening, false): Color(hex: "7E4FD0")
        case (.reading, true): Color(hex: "35D0A5")
        case (.reading, false): Color(hex: "1B9E78")
        case (.sentenceMining, true): Color(hex: "5AA0FF")
        case (.sentenceMining, false): Color(hex: "2F79D6")
        }
    }

    /// 135° fill for the resume hero (`baseColor` → `gradientPartner`).
    public var heroGradient: LinearGradient {
        LinearGradient(colors: [baseColor, gradientPartner],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}
