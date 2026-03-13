import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Collection.label) private var collections: [Collection]
    
    @StateObject private var viewModel = ContentViewModel()
    
    @State private var selection: String? = "dashboard"
    @State private var showingSettings = false
    @State private var showingAddCollection = false
    
    var body: some View {
        NavigationSplitView {
            SidebarView(
                selection: $selection,
                collections: collections,
                onSync: { _ in }, // Handled in detail view largely
                onDelete: { collection in
                    viewModel.deleteCollection(collection, selection: $selection, modelContext: modelContext)
                },
                onAdd: { showingAddCollection = true }
            )
            .toolbar {
                // Toolbar moved to top level to persist across selection changes
            }
            .alert("Sync Error", isPresented: $viewModel.showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage)
            }
        } detail: {
            if selection == "dashboard" {
                DashboardView()
            } else if let selection = selection, let collection = collections.first(where: { $0.id == selection }) {
                WallpaperGrid(collection: collection)
                    .navigationTitle(collection.label)
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            Button(action: { viewModel.syncCollection(collection, modelContext: modelContext) }) {
                                Label("Sync", systemImage: "arrow.triangle.2.circlepath")
                                    .symbolEffect(.bounce, value: viewModel.isSyncing)
                            }
                            .disabled(viewModel.isSyncing)
                        }
                    }
                    .safeAreaInset(edge: .bottom) {
                        if viewModel.isSyncing {
                            HStack {
                                ProgressView(value: viewModel.syncProgress)
                                    .progressViewStyle(.linear)
                                    .frame(maxWidth: 200)
                                Text(viewModel.syncStatusText)
                                    .font(.caption)
                                    .monospacedDigit()
                            }
                            .padding()
                            .background(.regularMaterial)
                            .clipShape(Capsule())
                            .padding()
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
            } else {
                ContentUnavailableView(
                    "Select a Collection",
                    systemImage: "folder.fill",
                    description: Text("Choose a collection from the sidebar to view your wallpapers.")
                )
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                 Button(action: { showingSettings = true }) {
                     Label("Settings", systemImage: "gear")
                 }
            }
        }
        .sheet(isPresented: $showingAddCollection) {
            AddCollectionView()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .onAppear {
            // Give the service access to the model context (via container)
            ShuffleService.shared.modelContainer = modelContext.container
        }
    }
}
