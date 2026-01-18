# DayProgressMenubar (SwiftUI macOS menubar app)

A minimal SwiftUI menubar app that shows how far through the current day you are.

## Requirements

- macOS 13+ (MenuBarExtra)
- Xcode 15+ (recommended)

## Open in Xcode

1. Open Xcode.
2. File -> Open... -> select this `day-progress` folder.
3. Choose the `DayProgressMenubar` scheme and Run.

## Hide Dock icon (recommended)

In Xcode: Target -> Info -> add "Application is agent (UIElement)" = YES.
This sets `LSUIElement` so the app runs only in the menubar.

## Run from Terminal (macOS only)

```bash
swift run
```

## Day progress behavior

- Progress is calculated from the start of your local day to the start of the next day.
- The menubar label shows the current percent.
- The menu shows percent, time elapsed, time remaining, and the day window.
- The app updates every minute and when you open the menu.
- Launch at login can be toggled from the menu.

## Build a distributable app bundle

```bash
./scripts/build_app.sh
```

The `.app` bundle is created at `build/DayProgressMenubar.app`.

You can override the version and bundle id:

```bash
VERSION=0.1.0 BUNDLE_ID=com.adityathebe.dayprogressmenubar ./scripts/build_app.sh
```

## Create a release zip + SHA256

```bash
./scripts/package_release.sh 0.1.0
```

This writes `build/DayProgressMenubar.zip` and prints the SHA256 you need for Homebrew.
