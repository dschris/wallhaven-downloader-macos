# Wallhaven Downloader (macOS)

A menu-bar app that mirrors [Wallhaven](https://wallhaven.cc) collections to your Mac and
rotates the desktop wallpaper from them on a timer.

Built with SwiftUI and SwiftData, SwiftPM, no Xcode project file required.

## Features

- **Collections** — add a Wallhaven collection by username + collection id; the app pages
  through the collection and downloads each wallpaper at full resolution.
- **Local library** — files land in `~/Pictures/Wallhaven/<collection label>/` and are
  indexed in SwiftData, so the grid and the shuffler work from local files rather than
  re-hitting the API.
- **Shuffle** — sets a random wallpaper from one collection, or from everything you have
  downloaded, every N minutes.
- **Display modes** — either the same image on every display, or a different one per
  display (drawn without replacement while the pool allows it).
- **Space modes** — only the Space you are on (the macOS default), the same wallpaper
  following you into every Space, or a different wallpaper per Space as you visit them.
- **Menu bar only** — runs as an accessory app (`LSUIElement`), no Dock icon; the dashboard
  window opens on demand.
- **Launch at login** — optional, via `SMAppService`.
- **API key** — optional. Only needed for NSFW or private collections.

## Requirements

- macOS 14 (Sonoma) or later
- Swift 5.9 toolchain (Xcode or the Command Line Tools)

## Build

```bash
swift build -c release
./package_app.sh
```

`package_app.sh` assembles `Output/WallhavenDownloader.app`, injects an `Info.plist`,
copies the icon, and ad-hoc signs the bundle (`codesign --sign -`). It is not notarised, so
Gatekeeper will warn on first launch — right-click → Open, or move it to `/Applications`
first (which is also what `Launch at Login` expects).

For development, open `Package.swift` in Xcode or run `swift run`. There is no `.xcodeproj`;
SwiftPM is the source of truth.

## Usage

1. Launch the app — it installs itself in the menu bar.
2. Open the dashboard, add a collection (`username` and collection id from the Wallhaven URL:
   `wallhaven.cc/collections/<username>/<id>`), and sync it.
3. Pick a collection in the sidebar, hit the button on any wallpaper to set it immediately.
4. In Settings, enable shuffle, choose the interval, and choose which collection to draw from.

## Where things live

| Path | What |
| --- | --- |
| `~/Pictures/Wallhaven/<collection>/` | downloaded wallpapers |
| SwiftData store (app container) | `Collection` and `WallhavenImage` records |
| `UserDefaults` | settings, see below |

Settings keys: `isShuffleEnabled` (Bool), `shuffleFrequency` (seconds, floor of 60),
`shuffleCollectionId` (String; absent or `"all"` means every collection),
`wallhaven_api_key` (String), `wallpaperDisplayMode` (`sameAllDisplays` |
`differentPerDisplay`), `wallpaperSpaceMode` (`currentSpaceOnly` | `followAcrossSpaces` |
`differentPerSpace`).

## Architecture

| File | Role |
| --- | --- |
| `WallhavenDownloaderApp.swift` | `AppDelegate`, menu-bar setup, `ModelContainer`, dashboard window |
| `WallhavenAPI.swift` | Wallhaven API v1 client (`/collections/<user>/<id>`, paging, optional `apikey`) |
| `SyncService.swift` | actor; downloads a collection into `~/Pictures/Wallhaven`, reports progress |
| `ShuffleService.swift` | timer-driven wallpaper rotation; reads its settings from `UserDefaults` |
| `WallpaperService.swift` | applies images across displays and Spaces; observes Space and screen changes |
| `WallpaperSettings.swift` | the two mode enums and their `UserDefaults` keys |
| `Models.swift` | SwiftData models: `Collection`, `WallhavenImage` |
| `ContentView` / `SidebarView` / `DashboardView` / `WallpaperGrid` / `AddCollectionView` | UI |
| `SettingsView.swift` | settings sheet (download path, API key) |
| `MenuBarView.swift` | menu-bar menu |
| `LoginService.swift` | launch-at-login toggle |
| `ContentViewModel.swift` | view state |

## Known issues

- **Spaces cannot be enumerated.** No public API lists Spaces or writes to one you have not
  visited, so "different wallpaper per Space" assigns images *as you arrive* — a Space you
  never return to keeps whatever it had. The AppleScript `every desktop` trick survives as
  `WallpaperService.setWallpaperScript` but is deliberately not wired to a setting: on macOS 14
  it only reaches the current Space per display, so exposing it would promise more than it does.
- **Mixed modes interact simply.** "Different per display" plus "different per Space" means a
  Space switch advances one image and applies it to every display. Per-display variation is a
  property of shuffles, not of Spaces.
- No tests and no CI. The multi-display and Space code paths are macOS-only; they have not been
  compiled or run on a Mac yet.

## License

No licence file in the repository. Treat it as all rights reserved until one is added.
