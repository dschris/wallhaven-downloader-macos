import Foundation
import SwiftData

class ShuffleService: ObservableObject {
    static let shared = ShuffleService()
    
    private var timer: Timer?
    
    private var shuffleFrequency: Double {
        get { UserDefaults.standard.double(forKey: "shuffleFrequency") == 0 ? 3600 : UserDefaults.standard.double(forKey: "shuffleFrequency") }
    }
    
    private var isShuffleEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "isShuffleEnabled") }
    }
    
    private var selectedCollectionId: String? {
        get { 
            let id = UserDefaults.standard.string(forKey: "shuffleCollectionId")
            return (id == nil || id == "all") ? nil : id
        }
    }
    
    // We need access to the model context to find wallpapers.
    var modelContainer: ModelContainer? {
        didSet {
            // Restart timer when container is set, just in case
            startTimer()
        }
    }
    
    init() {
        // Observe changes to settings
        NotificationCenter.default.addObserver(self, selector: #selector(defaultsChanged), name: UserDefaults.didChangeNotification, object: nil)
        startTimer()
    }
    
    @objc func defaultsChanged() {
        startTimer()
    }
    
    // Called by UI when settings change
    func updateSettings() {
        startTimer()
    }
    
    func startTimer() {
        timer?.invalidate()
        
        guard isShuffleEnabled, let _ = modelContainer else { 
            print("Shuffle disabled or no model container")
            return 
        }
        
        // Ensure frequency is structurally valid (at least 1 minute)
        let frequency = max(60.0, shuffleFrequency)
        
        print("Starting shuffle timer for \(frequency) seconds")
        
        // Create a repeating timer
        timer = Timer.scheduledTimer(withTimeInterval: frequency, repeats: true) { [weak self] _ in
            Task {
                await self?.shuffleWallpaper()
            }
        }
    }
    
    func shuffleWallpaper() async {
        guard let container = modelContainer else { return }
        // Create a new context for this background task
        let context = ModelContext(container)
        
        // Fetch images
        var descriptor = FetchDescriptor<WallhavenImage>()
        
        if let collectionId = selectedCollectionId {
             // We need to filter by collection. 
             // SwiftData predicates with relationships can be tricky if not set up perfectly.
             // Simpler approach for now: Fetch all and filter in memory if relationship query fails, 
             // or construct predicate correctly.
             // collection.id == collectionId
             descriptor.predicate = #Predicate<WallhavenImage> { image in
                 image.collection?.id == collectionId
             }
        }
        
        do {
            let images = try context.fetch(descriptor)

            // Hand the whole pool to WallpaperService: the display mode decides
            // whether one image goes everywhere or each screen draws its own, and
            // a single image here would defeat the per-display option entirely.
            let urls = images.compactMap(\.localPath).map { URL(fileURLWithPath: $0) }
            guard !urls.isEmpty else {
                print("No images found to shuffle")
                return
            }

            print("Shuffling from \(urls.count) images")
            try await WallpaperService.shared.applyRandom(from: urls)

        } catch {
            print("Failed to shuffle wallpaper: \(error)")
        }
    }
}
