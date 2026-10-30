import SwiftUI
import SwiftData
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    /// Static reference so MenuBarView can access this reliably
    /// (NSApp.delegate may be wrapped by SwiftUI and fail the cast).
    static private(set) var shared: AppDelegate!
    
    var dashboardWindow: NSWindow?
    var modelContainer: ModelContainer!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        
        // Menu bar-only app – no dock icon
        NSApp.setActivationPolicy(.accessory)
        
        // Set app icon from bundle
        if let iconURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
           let icon = NSImage(contentsOf: iconURL) {
            NSApp.applicationIconImage = icon
        }
        
        // Create the model container
        do {
            modelContainer = try ModelContainer(for: Collection.self, WallhavenImage.self)
            ShuffleService.shared.modelContainer = modelContainer
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        
        setupDashboardWindow()
        showDashboard()
    }
    
    private func setupDashboardWindow() {
        let contentView = ContentView()
            .modelContainer(modelContainer)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 600),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.contentView = NSHostingView(rootView: contentView)
        window.title = "Wallhaven Downloader"
        window.center()
        window.isReleasedWhenClosed = false
        window.delegate = self
        
        dashboardWindow = window
    }
    
    /// Brings the dashboard window to the foreground.
    func showDashboard() {
        NSApp.setActivationPolicy(.regular)
        
        DispatchQueue.main.async { [weak self] in
            NSApp.activate(ignoringOtherApps: true)
            self?.dashboardWindow?.makeKeyAndOrderFront(nil)
        }
    }
    
    // MARK: - NSWindowDelegate
    
    func windowWillClose(_ notification: Notification) {
        // Revert to menu bar-only when the dashboard window closes
        DispatchQueue.main.async {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}

@main
struct WallhavenDownloaderApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("Wallhaven", systemImage: "photo.on.rectangle.angled") {
            MenuBarView()
        }
    }
}
