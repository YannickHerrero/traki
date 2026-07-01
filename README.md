# Traki

**The one-tap time tracker for language learners.** Open the app, tap one of four study modes, and a stopwatch starts immediately. Stop to see the session added to your day; statistics turn those sessions into streaks, trends and a consistency heatmap. Widgets and a Live Activity let you start and monitor a session without opening the app.

Built natively in **SwiftUI**, faithfully reproducing the **"Playful Cards"** design from the original prototype (see [`reference/`](reference/)).

## The four learning modes

| Mode | Color | What it covers |
|---|---|---|
| Flashcards | `#F6A93B` | Vocabulary / grammar deck review (spaced repetition) |
| Listening | `#B98BFF` | Podcasts, shows, music, audio immersion |
| Reading | `#35D0A5` | Books, articles, subtitles, any text study |
| Sentence Mining | `#5AA0FF` | Harvesting words + example sentences from native material |

## Requirements

- **Xcode 16.4+** (iOS 18.5 SDK) · **Swift 6**
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — `brew install xcodegen`

The Xcode project is **generated** from [`project.yml`](project.yml); it is not committed. Regenerate it any time with `xcodegen generate`.

## Build & run

```sh
brew install xcodegen          # once
xcodegen generate              # produces Traki.xcodeproj
open Traki.xcodeproj           # ⌘R in Xcode, or:

xcodebuild -project Traki.xcodeproj -scheme Traki \
  -destination 'platform=iOS Simulator,name=iPhone 16' build
```

## Architecture

Deployment target: **iOS 18.0** (the latest the installed toolchain builds). The design language targets iOS 26 / Liquid Glass; see **iOS 26 upgrade** below.

| Target | Type | Role |
|---|---|---|
| `TrakiKit` | local Swift package | Shared core: `Session` model + SwiftData store (App Group), `LearningMode`, palette/theme, bundled fonts, formatters, aggregations, `SessionController`, `AppSettings`, Live Activity attributes, App Intents |
| `Traki` | iOS app | Tab bar + Home / Statistics / History / Settings, the tracking flow, and the log/edit sheet |
| `TrakiWidgets` | widget extension | Home + Lock-Screen widgets, Live Activity + Dynamic Island |

`TrakiKit` and `TrakiWidgets` are introduced in later build phases; see [the plan](#project-status).

Every total in the app is **derived from individual `Session` rows**, so adding, editing or deleting an entry keeps the whole app consistent — the product's core guarantee.

## iOS 26 upgrade

The app is written **iOS-26-ready**. To promote it once **Xcode 26** is installed:

1. Bump `options.deploymentTarget.iOS` to `"26.0"` in `project.yml` and `xcodegen generate`.
2. Enable real Liquid Glass in the single `trakiGlass` view modifier (it renders standard materials below iOS 26).

## Project status

Built in small, atomic commits across phases: scaffolding → shared core → app shell → Home → tracking → logging → history → statistics → settings → widgets → App Intents → Live Activity → polish.

## Reference

The original design export (product spec, interactive prototype, style directions) lives in [`reference/`](reference/) and is the source of truth for behaviour, tokens and copy.
