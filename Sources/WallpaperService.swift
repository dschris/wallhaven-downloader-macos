import Foundation
import AppKit

/// Applies wallpapers across displays and Spaces.
///
/// The public API writes to *one* screen at a time
/// (`NSWorkspace.setDesktopImageURL(_:for:options:)`) and only to the Space that
/// screen is currently showing. Everything here covers the cases that leaves open:
/// several displays, and Spaces you are not looking at.
final class WallpaperService: NSObject {
    static let shared = WallpaperService()

    /// Candidate images for the current shuffle, used when a Space or display
    /// appears and we need something to put on it.
    private var pool: [URL] = []

    /// What we last put on each display, keyed by CGDirectDisplayID so the mapping
    /// survives a dock/undock, where NSScreen instances are replaced.
    private var lastURLByDisplay: [CGDirectDisplayID: URL] = [:]

    /// Position in `pool` for the "different per Space" mode.
    private var spaceCycleIndex = 0

    private var displayMode: WallpaperDisplayMode {
        WallpaperDisplayMode(rawValue: UserDefaults.standard.string(forKey: WallpaperSettingsKey.displayMode) ?? "")
            ?? .sameAllDisplays
    }

    private var spaceMode: WallpaperSpaceMode {
        WallpaperSpaceMode(rawValue: UserDefaults.standard.string(forKey: WallpaperSettingsKey.spaceMode) ?? "")
            ?? .currentSpaceOnly
    }

    private override init() {
        super.init()
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(activeSpaceDidChange(_:)),
            name: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersDidChange(_:)),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    // MARK: - Public API

    /// Apply one specific image to every attached display. Used when the user picks
    /// a wallpaper explicitly: that choice overrides the per-display mode for the
    /// moment, but does not disturb the shuffle pool.
    @MainActor
    func setWallpaper(url: URL) throws {
        for screen in NSScreen.screens {
            try set(url, on: screen)
            lastURLByDisplay[displayID(of: screen)] = url
        }
    }

    /// Pick from `urls` according to the display mode and apply the result.
    @MainActor
    func applyRandom(from urls: [URL]) throws {
        guard !urls.isEmpty else { return }
        pool = urls

        switch displayMode {
        case .sameAllDisplays:
            guard let pick = urls.randomElement() else { return }
            for screen in NSScreen.screens {
                try set(pick, on: screen)
                lastURLByDisplay[displayID(of: screen)] = pick
            }

        case .differentPerDisplay:
            let screens = NSScreen.screens
            guard !screens.isEmpty else { return }

            // Draw without replacement so two displays never share an image while
            // the pool allows it, then fall back to repeating.
            var picks = urls.shuffled()
            if picks.count < screens.count {
                picks = (0..<screens.count).map { _ in urls.randomElement()! }
            }

            for (index, screen) in screens.enumerated() {
                let url = picks[index % picks.count]
                try set(url, on: screen)
                lastURLByDisplay[displayID(of: screen)] = url
            }
        }
    }

    // MARK: - Spaces

    @objc private func activeSpaceDidChange(_ notification: Notification) {
        guard spaceMode != .currentSpaceOnly else { return }

        Task { @MainActor in
            // The notification arrives before the incoming Space will accept a
            // desktop image; writing immediately lands on the Space you just left.
            try? await Task.sleep(nanoseconds: 400_000_000)
            self.applyForNewSpace()
        }
    }

    @MainActor
    private func applyForNewSpace() {
        let screens = NSScreen.screens
        guard !screens.isEmpty else { return }

        switch spaceMode {
        case .currentSpaceOnly:
            return

        case .followAcrossSpaces:
            // Whatever each display is showing follows it into the new Space.
            let fallback = lastURLByDisplay.values.first ?? pool.first
            for screen in screens {
                let url = lastURLByDisplay[displayID(of: screen)] ?? fallback
                guard let url else { continue }
                try? set(url, on: screen)
            }

        case .differentPerSpace:
            guard !pool.isEmpty else { return }
            let url = pool[spaceCycleIndex % pool.count]
            spaceCycleIndex += 1
            for screen in screens {
                try? set(url, on: screen)
                lastURLByDisplay[displayID(of: screen)] = url
            }
        }
    }

    // MARK: - Displays appearing and disappearing

    @objc private func screenParametersDidChange(_ notification: Notification) {
        Task { @MainActor in
            // Give the window server a moment to finish reconfiguring.
            try? await Task.sleep(nanoseconds: 300_000_000)
            self.restoreForCurrentScreens()
        }
    }

    /// After docking or undocking, screens come back with whatever wallpaper macOS
    /// saved for them. Put our last choice back, and give a display we have never
    /// seen something from the pool rather than leaving it bare.
    @MainActor
    private func restoreForCurrentScreens() {
        let fallback = lastURLByDisplay.values.first ?? pool.first
        for screen in NSScreen.screens {
            let url = lastURLByDisplay[displayID(of: screen)] ?? fallback
            guard let url else { continue }
            try? set(url, on: screen)
            lastURLByDisplay[displayID(of: screen)] = url
        }
    }

    // MARK: - Primitives

    @MainActor
    private func set(_ url: URL, on screen: NSScreen) throws {
        try NSWorkspace.shared.setDesktopImageURL(url, for: screen, options: [:])
    }

    private func displayID(of screen: NSScreen) -> CGDirectDisplayID {
        let key = NSDeviceDescriptionKey("NSScreenNumber")
        guard let number = screen.deviceDescription[key] as? NSNumber else { return 0 }
        return number.uint32Value
    }

    // MARK: - Escape hatch (not wired to any setting)

    /// Sets the picture on every "desktop" System Events knows about. Kept as a
    /// manual fallback only: on macOS 14 this reaches the Space each display is
    /// currently showing, so it is no better than the API path above. Wiring it to
    /// a UI option would promise something it cannot deliver.
    func setWallpaperScript(path: String) {
        let scpt = """
        tell application "System Events"
            tell every desktop
                set picture to "\(path)"
            end tell
        end tell
        """

        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: scpt) {
            scriptObject.executeAndReturnError(&error)
            if let error {
                print("AppleScript Error: \(error)")
            }
        }
    }
}
