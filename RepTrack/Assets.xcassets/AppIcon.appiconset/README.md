# RepTrack App Icon

Raster PNGs in this set are generated from the master **1024×1024** image (`AppIcon-1024.png`). The asset catalog lists explicit **iPhone** and **iPad** slots (including **60pt @2x** → 120×120 and **76pt @2x** → 152×152).

## Project settings

- **App Icons Source / Asset Catalog App Icon Set Name:** `AppIcon` (`ASSETCATALOG_COMPILER_APPICON_NAME`)
- **Generated Info.plist:** `CFBundleIconName` = `AppIcon` (`INFOPLIST_KEY_CFBundleIconName`)

## Regenerating sizes

From a new 1024×1024 master `source.png`:

```bash
for s in 20 29 40 58 60 76 80 87 120 152 167 180 1024; do
  sips -z $s $s source.png --out "AppIcon-${s}.png"
done
```

Optional in-app artwork can still use `AppIconView` in SwiftUI; the store / home screen use this **AppIcon** set.
