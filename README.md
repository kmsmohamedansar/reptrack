# RepTrack

iOS training log: workouts, exercises, sets (reps and weight). Local-first with SwiftData. Built as a NorthStar Forge product.

## What it does

Fast set entry, session history on device, and progression cues without account friction for core logging. Scope is gym use, not social feeds.

## Stack

Swift, SwiftUI, SwiftData, iOS 17+.

## Highlights

- Domain-shaped SwiftData models for workouts and sets
- UI tuned for quick input between sets
- App Store Connect track (status on your portfolio site)

## Run

Open the Xcode project under `RepTrack/` (or your canonical app target), set signing, run on simulator or device. Minimum iOS 17.

## Light mode only

The app is **light mode only** so the Forge palette and contrast stay intentional.

- **SwiftUI**: Root view enforces `.preferredColorScheme(.light)` in `RepTrackApp.swift`.
- **Info.plist**: `UIUserInterfaceStyle = Light` via build settings where applicable.

## Status

Active development. Public code may lag the App Store binary.

## License

Specify in-repo if you add one.
