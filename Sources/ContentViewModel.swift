import Foundation
import SwiftData
import SwiftUI

@MainActor
class ContentViewModel: ObservableObject {
    @Published var isSyncing = false
    @Published var showingError = false
    @Published var errorMessage = ""
    @Published var syncProgress: Double = 0.0
    @Published var syncStatusText = ""
    
    func syncCollection(_ collection: Collection, modelContext: ModelContext) {
        isSyncing = true
        syncProgress = 0.0
        syncStatusText = "Initializing..."
        
        let username = collection.username ?? "intel777"
        let knownIds = Set(collection.images.map { $0.id })
        
        Task {
            do {
                let newImages = try await SyncService.shared.syncCollection(collectionId: collection.id, label: collection.label, username: username, knownIds: knownIds) { [weak self] current, total in
                    Task { @MainActor in
                        self?.syncProgress = Double(current) / Double(total)
                        self?.syncStatusText = "Downloading \(current) of \(total)..."
                    }
                }
                
                // Update ModelContext on MainActor
                // Update ModelContext on MainActor
                for (dto, url) in newImages {
                    let thumb = dto.thumbs.large
                    
                    if let existingImage = collection.images.first(where: { $0.id == dto.id }) {
                        // Update existing record
                        existingImage.url = dto.path
                        existingImage.localPath = url.path
                        existingImage.thumbnailUrl = thumb
                    } else {
                        // Insert new record
                        let newImage = WallhavenImage(id: dto.id, url: dto.path, thumbnailUrl: thumb, localPath: url.path)
                        newImage.collection = collection
                        modelContext.insert(newImage)
                    }
                }
                self.isSyncing = false
                
            } catch {
                self.isSyncing = false
                self.errorMessage = "Failed to sync collection: \(error.localizedDescription)\n\nCheck your API Key, Collection ID, and Username."
                self.showingError = true
            }
        }
    }
    
    func deleteCollection(_ collection: Collection, selection: Binding<String?>, modelContext: ModelContext) {
        if selection.wrappedValue == collection.id {
            selection.wrappedValue = nil
        }
        modelContext.delete(collection)
    }
}
