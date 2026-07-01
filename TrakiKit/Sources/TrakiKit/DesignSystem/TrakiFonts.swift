import CoreText
import Foundation

/// Registers the bundled Nunito / Barlow / Barlow Semi Condensed faces with
/// CoreText so both the app and the widget extension can use them.
///
/// Registration runs exactly once per process. The `Font.traki*` helpers call
/// ``register()`` lazily, so callers don't have to — but the app also calls it
/// explicitly at launch to avoid a first-frame fallback flash.
public enum TrakiFonts {
    /// Bundled face PostScript names, used both for registration bookkeeping and
    /// by the `Font` helpers when resolving a weight.
    static let faceFileNames = [
        "Nunito-SemiBold", "Nunito-Bold", "Nunito-ExtraBold", "Nunito-Black",
        "Barlow-Regular", "Barlow-Medium", "Barlow-SemiBold", "Barlow-Bold", "Barlow-ExtraBold",
        "BarlowSemiCondensed-Medium", "BarlowSemiCondensed-SemiBold",
        "BarlowSemiCondensed-Bold", "BarlowSemiCondensed-ExtraBold",
    ]

    /// Idempotent, thread-safe: the static `let` body runs once on first access.
    public static func register() { _ = registrationToken }

    private static let registrationToken: Void = {
        let urls = Bundle.module.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? []
        for url in urls {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }()
}
