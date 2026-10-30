import Foundation

/// Keys for the wallpaper behaviour settings. Shared between the settings UI and
/// the service so a rename can't silently detach the picker from the behaviour.
enum WallpaperSettingsKey {
    static let displayMode = "wallpaperDisplayMode"
    static let spaceMode = "wallpaperSpaceMode"
}

/// How a single shuffle is distributed across attached displays.
enum WallpaperDisplayMode: String, CaseIterable, Identifiable {
    /// One image, set on every display. What most people expect.
    case sameAllDisplays
    /// A different image per display, drawn without replacement where the pool is
    /// large enough. Falls back to repeats when there are more screens than images.
    case differentPerDisplay

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sameAllDisplays: return "Same image on every display"
        case .differentPerDisplay: return "Different image per display"
        }
    }

    var detail: String {
        switch self {
        case .sameAllDisplays:
            return "One wallpaper is chosen per shuffle and applied to all displays."
        case .differentPerDisplay:
            return "Each display gets its own wallpapers. If you keep the same collection, no two displays share an image until the pool runs out."
        }
    }
}

/// How the app behaves when you move between Spaces (virtual desktops).
enum WallpaperSpaceMode: String, CaseIterable, Identifiable {
    /// macOS default: the app writes to the Space you are on and nothing else.
    case currentSpaceOnly
    /// The last chosen wallpaper follows you: switching to another Space reapplies it
    /// there, so no Space keeps a stale image.
    case followAcrossSpaces
    /// Every Space you visit takes the next image from the pool, so Spaces differ.
    case differentPerSpace

    var id: String { rawValue }

    var title: String {
        switch self {
        case .currentSpaceOnly: return "Only the Space I'm on"
        case .followAcrossSpaces: return "Same wallpaper in every Space"
        case .differentPerSpace: return "Different wallpaper per Space"
        }
    }

    var detail: String {
        switch self {
        case .currentSpaceOnly:
            return "macOS only applies the change to the current Space. Other Spaces keep whatever they had."
        case .followAcrossSpaces:
            return "When you switch Spaces, the current wallpaper is reapplied there. Existing Spaces are fixed as you visit them."
        case .differentPerSpace:
            return "Each Space you switch to advances to the next image, so your Spaces look different. The sequence is deterministic per session."
        }
    }
}
