import SwiftUI

struct MenuBarView: View {
    @Environment(\.openWindow) var openWindow
    
    var body: some View {
        Button("Next Wallpaper") {
            Task {
                print("Next wallpaper requested via Menu Bar")
                await ShuffleService.shared.shuffleWallpaper()
            }
        }
        
        Divider()
        
        Button("Open Dashboard") {
            openWindow(id: "main") // Needs handling in App setup to identify window
        }
        
        Divider()
        
        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
    }
}
