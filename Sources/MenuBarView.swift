import SwiftUI

struct MenuBarView: View {
    var body: some View {
        Button("Next Wallpaper") {
            Task {
                print("Next wallpaper requested via Menu Bar")
                await ShuffleService.shared.shuffleWallpaper()
            }
        }
        
        Divider()
        
        Button("Open Dashboard") {
            AppDelegate.shared?.showDashboard()
        }
        
        Divider()
        
        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
    }
}
