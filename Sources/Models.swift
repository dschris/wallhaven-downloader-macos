import SwiftUI
import SwiftData

@Model
class Collection {
    @Attribute(.unique) var id: String
    var label: String
    var path: String
    var username: String? // Optional, no default
    @Relationship(deleteRule: .cascade) var images: [WallhavenImage] = []
    
    init(id: String, label: String, path: String, username: String) {
        self.id = id
        self.label = label
        self.path = path
        self.username = username
    }
}

@Model
class WallhavenImage {
    @Attribute(.unique) var id: String
    var url: String
    var thumbnailUrl: String?
    var localPath: String?
    var collection: Collection?
    
    init(id: String, url: String, thumbnailUrl: String? = nil, localPath: String? = nil) {
        self.id = id
        self.url = url
        self.thumbnailUrl = thumbnailUrl
        self.localPath = localPath
    }
}
