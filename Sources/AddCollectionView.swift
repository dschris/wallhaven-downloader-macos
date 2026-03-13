import SwiftUI

struct AddCollectionView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    
    @State private var label: String = ""
    @State private var collectionId: String = ""
    @State private var username: String = "" 
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "plus.rectangle.on.folder.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 48, height: 48)
                .foregroundStyle(.tint)
            
            Text("Add New Collection")
                .font(.title2)
                .bold()
            
            Form {
                Section {
                    TextField("Label (e.g. Scifi)", text: $label)
                    TextField("Collection ID (e.g. 12345)", text: $collectionId)
                        .help("The ID found in the URL of the Wallhaven collection")
                }
                
                Section {
                    TextField("Username", text: $username)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Optional Configuration")
                }
            }
            .formStyle(.grouped)
            
            HStack {
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Add Collection") {
                    addCollection()
                }
                .buttonStyle(.borderedProminent)
                .disabled(label.isEmpty || collectionId.isEmpty || username.isEmpty)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .frame(width: 350, height: 350)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private func addCollection() {
        let newCol = Collection(id: collectionId, label: label, path: "", username: username)
        modelContext.insert(newCol)
        dismiss()
    }
}
