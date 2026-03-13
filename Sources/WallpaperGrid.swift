
import SwiftUI
import SwiftData

struct WallpaperGrid: View {
    let collection: Collection
    @Environment(\.modelContext) private var modelContext
    
    // Grid configuration
    let columns = [
        GridItem(.adaptive(minimum: 200, maximum: 300), spacing: 16)
    ]
    
    var body: some View {
        ScrollView {
            if collection.images.isEmpty {
                 ContentUnavailableView {
                    Label("No Wallpapers", systemImage: "photo.on.rectangle.angled")
                } description: {
                    Text("Sync this collection to download wallpapers.")
                } actions: {
                    // Action handled by parent usually, but we can expose it or use a binding
                    // For now, simple text
                }
                .padding(.top, 100)
            } else {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(collection.images) { image in
                        WallpaperCell(image: image)
                    }
                }
                .padding()
            }
        }
    }
}

struct WallpaperCell: View {
    let image: WallhavenImage
    @State private var isHovering = false
    @State private var showCheckmark = false
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Use thumbnail if available, else full resolution (fallback)
            AsyncImage(url: URL(string: image.thumbnailUrl ?? image.url)) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(Color.secondary.opacity(0.1))
                        .overlay(ProgressView())
                case .success(let img):
                    img
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .frame(height: 160)
                        .clipped()
                case .failure:
                    ZStack {
                        Rectangle().fill(Color.secondary.opacity(0.1))
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundStyle(.secondary)
                    }
                @unknown default:
                    EmptyView()
                }
            }
            .frame(height: 160)
            .frame(minWidth: 0, maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            
            // Hover Overlay
            if isHovering {
                ZStack {
                    Color.black.opacity(0.2)
                    
                    Button(action: setWallpaper) {
                        Label("Set as Wallpaper", systemImage: "display")
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.thinMaterial)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Downloaded Indicator
            if image.localPath != nil {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.white, .green)
                    .padding(8)
                    .shadow(radius: 2)
            }
        }
        .frame(height: 160)
        .onHover { hover in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hover
            }
        }
        .onTapGesture {
            // Optional: Open detail view
        }
    }
    
    private func setWallpaper() {
        Task {
            if let localPath = image.localPath {
                try? await WallpaperService.shared.setWallpaper(url: URL(fileURLWithPath: localPath))
            } else if let downloadUrl = URL(string: image.url) {
                // Trigger quick download if needed, but optimally we use SyncService
                // ensuring localPath is updated.
                // For now, fire & forget
            }
        }
    }
}
