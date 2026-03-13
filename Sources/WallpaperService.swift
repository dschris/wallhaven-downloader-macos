import Foundation
import AppKit

class WallpaperService {
    static let shared = WallpaperService()
    
    // Set wallpaper using NSWorkspace (macOS API)
    // Note: This requires the app to be sandboxed correctly or have permissions?
    // Actually NSWorkspace.shared.setDesktopImageURL is the standard way.
    @MainActor
    func setWallpaper(url: URL, for screen: NSScreen = NSScreen.main!) throws {
        try NSWorkspace.shared.setDesktopImageURL(url, for: screen, options: [:])
    }
    
    // Fallback/Legacy method using AppleScript if needed (e.g. for multi-monitor handling that NSWorkspace might find tricky, though NSWorkspace is generally better now)
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
            if let error = error {
                print("AppleScript Error: \(error)")
            }
        }
    }
}
