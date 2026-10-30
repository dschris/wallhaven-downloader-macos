import SwiftUI

struct SettingsView: View {
    @AppStorage("wallhaven_api_key") private var apiKey: String = ""
    @AppStorage("download_path") private var downloadPath: String = "~/Pictures/Wallhaven"
    @AppStorage(WallpaperSettingsKey.displayMode) private var displayMode: WallpaperDisplayMode = .sameAllDisplays
    @AppStorage(WallpaperSettingsKey.spaceMode) private var spaceMode: WallpaperSpaceMode = .currentSpaceOnly
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "gear")
                    .font(.system(size: 24))
                    .foregroundStyle(.secondary)
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding()
            .background(.thinMaterial)
            
            Form {
                Section {
                    TextField("Download Path", text: $downloadPath)
                    Text("Default location for new collections.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Label("General", systemImage: "folder")
                }
                
                Section {
                    SecureField("API Key", text: $apiKey)
                    Text("Required for NSFW or private collections.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Link("Get API Key from Wallhaven", destination: URL(string: "https://wallhaven.cc/settings/account")!)
                        .font(.caption)
                } header: {
                    Label("Wallhaven API", systemImage: "key")
                }

                Section {
                    Picker("Across displays", selection: $displayMode) {
                        ForEach(WallpaperDisplayMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.radioGroup)

                    Text(displayMode.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Picker("Across Spaces", selection: $spaceMode) {
                        ForEach(WallpaperSpaceMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.radioGroup)
                    .padding(.top, 8)

                    Text(spaceMode.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Changing either option takes effect at the next shuffle or Space switch. Picking a wallpaper from the grid still applies it to every display.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 4)
                } header: {
                    Label("Wallpaper Behaviour", systemImage: "display.2")
                }
            }
            .formStyle(.grouped)
            
            HStack {
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
            .padding()
            .background(.thinMaterial)
        }
        .frame(width: 460, height: 620)
    }
}
