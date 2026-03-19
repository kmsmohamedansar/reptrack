# RepTrack (Northstar Forge)

## Light-mode only

This app is **designed for light mode only** to preserve the intended Forge color palette and contrast.

- **SwiftUI**: The root view in `RepTrackApp.swift` enforces `.preferredColorScheme(.light)`.
- **Info.plist**: The project sets `UIUserInterfaceStyle = Light` via build settings (generated Info.plist).

