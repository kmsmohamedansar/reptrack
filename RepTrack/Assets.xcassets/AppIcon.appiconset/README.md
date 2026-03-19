# Northstar Forge App Icon

The app icon is drawn in code by `AppIconView` (see `Views/Components/AppIconView.swift`).

## To generate the 1024×1024 asset

1. **Option A – Preview export (Xcode 14+)**  
   Open `AppIconView.swift`, run the preview, then use **File → Export** from the preview canvas (or screenshot the 1024pt preview).

2. **Option B – ImageRenderer (iOS 16+)**  
   In code, use:
   ```swift
   let view = AppIconView(variation: .standard, size: 1024)
   let renderer = ImageRenderer(content: view)
   if let image = renderer.uiImage {
       // Save or copy image to AppIcon.appiconset as AppIcon.png
   }
   ```

3. **Option C – Simulator screenshot**  
   Add a temporary screen that shows `AppIconView(size: 1024)` full screen, run in Simulator, then **File → Save Screen** (or Cmd+S) and crop to 1024×1024.

## Icon variations

- **Standard (A):** North star above hammer + anvil + minimal ring.
- **Variation B:** Hammer striking star spark.
- **Variation C:** Minimal north star emblem only.

Use `AppIconView(variation: .hammerSpark, size: 1024)` or `.starOnly` for B/C.

## Sizes

Use the 1024×1024 image in the **AppIcon** set. Xcode will generate 60, 76, 83.5, 1024, etc. from it. Ensure the single 1024×1024 slot in this appiconset references your exported PNG.
