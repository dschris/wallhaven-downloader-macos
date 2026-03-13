import Foundation
import ServiceManagement

class LoginService: ObservableObject {
    static let shared = LoginService()
    
    @Published var isEnabled: Bool = false
    
    init() {
        self.isEnabled = SMAppService.mainApp.status == .enabled
    }
    
    func updateStatus() {
        self.isEnabled = SMAppService.mainApp.status == .enabled
    }
    
    func toggle(enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status == .enabled { return }
                try SMAppService.mainApp.register()
            } else {
                if SMAppService.mainApp.status == .notRegistered { return }
                try SMAppService.mainApp.unregister()
            }
            updateStatus()
        } catch {
            print("Failed to toggle login item: \(error)")
            // If checking fails, it might be because we aren't packaged. 
            // We'll update the status to reflect reality.
            updateStatus()
        }
    }
}
