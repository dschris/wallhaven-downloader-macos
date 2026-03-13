import SwiftUI

struct SettingsView: View {
    @AppStorage("wallhaven_api_key") private var apiKey: String = ""
    @AppStorage("download_path") private var downloadPath: String = "~/Pictures/Wallhaven"
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
        .frame(width: 450, height: 400)
    }
}
