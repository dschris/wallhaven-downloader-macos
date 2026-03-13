import Foundation
import SwiftData

actor SyncService {
    static let shared = SyncService()
    private let api = WallhavenAPI.shared
    private let downloadPath: URL
    
    init() {
        // Default to ~/Pictures/Wallhaven
        let pictures = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first!
        self.downloadPath = pictures.appendingPathComponent("Wallhaven")
        
        try? FileManager.default.createDirectory(at: downloadPath, withIntermediateDirectories: true)
    }
    
    func syncCollection(collectionId: String, label: String, username: String, knownIds: Set<String> = [], onProgress: ((Int, Int) -> Void)? = nil) async throws -> [(dto: WallhavenImageDTO, localPath: URL)] {
        // Create collection folder
        let collectionURL = downloadPath.appendingPathComponent(label)
        try? FileManager.default.createDirectory(at: collectionURL, withIntermediateDirectories: true)
        
        // Fetch collection
        let apiKey = UserDefaults.standard.string(forKey: "wallhaven_api_key")
        
        var downloadedImages: [(WallhavenImageDTO, URL)] = []
        var lastPage = 1
        var totalImages = 0
        var processedImages = 0
        
        // Initial fetch to get meta
        let firstResponse = try await api.getCollection(username: username, id: collectionId, page: 1, apiKey: apiKey)
        lastPage = firstResponse.meta.last_page
        totalImages = firstResponse.meta.total
        
        // Process first page
        var pageHasNewContent = false
        for imageDTO in firstResponse.data {
             let isNew = await processImage(imageDTO, collectionURL: collectionURL, knownIds: knownIds, downloadedImages: &downloadedImages)
             if isNew { pageHasNewContent = true }
             processedImages += 1
             onProgress?(processedImages, totalImages)
        }
        
        // If first page had absolutely no new content (all known IDs and files exist), we can probably stop.
        // However, to be safe, typically we check if *all* items on the page were skipped.
        // Only stop if we are on page 1 and it was fully skipped? 
        // Or strictly if we encounter a full page of "known" items.
        // Let's go with: if the page was full and NO new processing happened, break.
        if !pageHasNewContent && !firstResponse.data.isEmpty {
            // Optimization: Stop here
            return downloadedImages
        }
        
        // Fetch remaining pages
        if lastPage > 1 {
            for page in 2...lastPage {
                // Rate limit
                try await Task.sleep(nanoseconds: 1_200_000_000) // 1.2s delay
                
                let response = try await api.getCollection(username: username, id: collectionId, page: page, apiKey: apiKey)
                
                var currentPageHasNewContent = false
                for imageDTO in response.data {
                    let isNew = await processImage(imageDTO, collectionURL: collectionURL, knownIds: knownIds, downloadedImages: &downloadedImages)
                    if isNew { currentPageHasNewContent = true }
                    processedImages += 1
                    onProgress?(processedImages, totalImages)
                }
                
                if !currentPageHasNewContent && !response.data.isEmpty {
                    break
                }
            }
        }
        
        return downloadedImages
    }
    
    // Returns true if the image required action (download or DB update needed)
    // Returns false if we have it and it's in the DB (knownId)
    private func processImage(_ imageDTO: WallhavenImageDTO, collectionURL: URL, knownIds: Set<String>, downloadedImages: inout [(WallhavenImageDTO, URL)]) async -> Bool {
        // Extract extension from URL, default to jpg if unknown
        let ext = URL(string: imageDTO.path)?.pathExtension ?? "jpg"
        let fileURL = collectionURL.appendingPathComponent("\(imageDTO.id).\(ext)")
        
        let fileExists = FileManager.default.fileExists(atPath: fileURL.path)
        let isKnown = knownIds.contains(imageDTO.id)
        
        if isKnown && fileExists {
            // We have the file and the DB record.
            // This is a "clean skip".
            // We do NOT append to downloadedImages so ContentViewModel doesn't re-process it.
            return false
        }
        if !fileExists {
            // Download
            if let downloadUrl = URL(string: imageDTO.path) {
                do {
                    let (data, _) = try await URLSession.shared.data(from: downloadUrl)
                    try data.write(to: fileURL)
                } catch {
                    print("Failed to download \(imageDTO.id): \(error)")
                }
            }
        }
        
        downloadedImages.append((imageDTO, fileURL))
        return true // We processed it (downloaded or verified existence for non-known ID)
    }
    
    func downloadImage(url: URL, to destination: URL) async throws {
        let (data, _) = try await URLSession.shared.data(from: url)
        try data.write(to: destination)
    }
}
