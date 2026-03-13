import SwiftUI

struct SidebarView: View {
    @Binding var selection: String?
    let collections: [Collection]
    let onSync: (Collection) -> Void
    let onDelete: (Collection) -> Void
    let onAdd: () -> Void
    
    var body: some View {
        List(selection: $selection) {
            NavigationLink(value: "dashboard") {
                Label("Dashboard", systemImage: "gauge")
            }
            
            Section("Collections") {
                ForEach(collections) { collection in
                    NavigationLink(value: collection.id) {
                        HStack {
                            Label(collection.label, systemImage: "folder")
                            Spacer()
                            Text("\(collection.images.count)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .contextMenu {
                         Button(role: .destructive) {
                             onDelete(collection)
                         } label: {
                             Label("Delete", systemImage: "trash")
                         }
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom) {
            Button(action: onAdd) {
                Label("Add Collection", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderless)
            .background(.ultraThinMaterial)
        }
    }
}
