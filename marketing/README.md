# Marketing Assets

BoxIndex marketing assets live here.

## Folder layout

- `raw-screens/iphone/`
- `raw-screens/ipad-13/`
- `app-store/`
- `social/`

## Expected raw screenshot names

Place iPhone screenshots in `raw-screens/iphone/` with these names:

- `01-home.png`
- `02-container-detail.png`
- `03-container-editor.png`
- `04-search.png`
- `05-scan-label.png`
- `06-scan-qr.png`
- `07-qr-output.png`
- `08-backup.png`

If you later want iPad App Store screenshots, reuse the same file names in `raw-screens/ipad-13/`.

## Scripts

Generate social "coming soon" assets:

```bash
swift Scripts/GenerateSocialCollage.swift
```

This script works even before screenshots exist. When a matching screenshot is missing, it renders a branded placeholder card instead.

Generate App Store marketing screenshots:

```bash
swift Scripts/GenerateMarketingScreenshots.swift
```

This script expects the raw screenshots above. If they are missing, it prints the missing file names and skips that output family cleanly.

## Notes

- Social output is written to `social/`.
- App Store output is written to `app-store/`.
- The social script uses the BoxIndex app icon from the asset catalog automatically.
