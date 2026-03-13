import SwiftUI
import SwiftData

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Force the app to be a regular app (dock icon, menu bar)
        NSApp.setActivationPolicy(.regular)
        
        // Activate the app (bring to foreground) to allow text input
        // slightly delayed to ensure window is ready
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            NSApp.windows.first?.makeKeyAndOrderFront(nil)
        }
    }
}

@main
struct WallhavenDownloaderApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    let container: ModelContainer

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
        
        MenuBarExtra("Wallhaven", systemImage: "photo.on.rectangle.angled") {
            MenuBarView()
        }
    }
    
    init() {
        do {
            container = try ModelContainer(for: Collection.self, WallhavenImage.self)
            // Inject dependency into background service
            ShuffleService.shared.modelContainer = container
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
}
