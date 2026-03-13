import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query(sort: \Collection.label) private var collections: [Collection]
    @StateObject private var loginService = LoginService.shared
    
    @AppStorage("shuffleFrequency") private var shuffleFrequency: Double = 3600 // Seconds
    @AppStorage("isShuffleEnabled") private var isShuffleEnabled: Bool = false
    @AppStorage("shuffleCollectionId") private var shuffleCollectionId: String = "all"
    
    // Timer handling would ideally be in a service or view model, but for simple config:
    // The actual shuffling logic needs to run in the background (AppDelegate or a Service)
    
    var body: some View {
        Form {
            Section("Wallpaper Shuffle") {
                Toggle("Enable Shuffle", isOn: $isShuffleEnabled)
                    .onChange(of: isShuffleEnabled) { _, _ in
                         ShuffleService.shared.updateSettings()
                    }
                
                Toggle("Launch at Login", isOn: Binding(
                    get: { loginService.isEnabled },
                    set: { loginService.toggle(enabled: $0) }
                ))
                
                if isShuffleEnabled {
                    Picker("Change Every", selection: $shuffleFrequency) {
                        Text("5 Minutes").tag(300.0)
                        Text("10 Minutes").tag(600.0)
                        Text("15 Minutes").tag(900.0)
                        Text("30 Minutes").tag(1800.0)
                        Text("1 Hour").tag(3600.0)
                        Text("6 Hours").tag(21600.0)
                        Text("12 Hours").tag(43200.0)
                        Text("24 Hours").tag(86400.0)
                    }
                    .onChange(of: shuffleFrequency) { _, _ in
                         ShuffleService.shared.updateSettings()
                    }
                    
                    Picker("From Collection", selection: $shuffleCollectionId) {
                        Text("All Collections").tag("all")
                        ForEach(collections) { collection in
                            Text(collection.label).tag(collection.id)
                        }
                    }
                    .onChange(of: shuffleCollectionId) { _, _ in
                         ShuffleService.shared.updateSettings()
                    }
                }
            }
            
            Section {
                Button(action: {
                    Task {
                        await ShuffleService.shared.shuffleWallpaper()
                    }
                }) {
                    Label("Next Wallpaper", systemImage: "arrow.right.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
            }
            
            Section {
               // Placeholder for stats or recent activity
               Text("Select a collection from the sidebar to manage your wallpapers.")
                   .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Dashboard")
    }
}
