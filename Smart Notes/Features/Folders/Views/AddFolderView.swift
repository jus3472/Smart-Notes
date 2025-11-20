// Features/Folders/Views/AddFolderView.swift
import SwiftUI

struct AddFolderView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var foldersViewModel: FoldersViewModel   // use Firebase view model
    
    @State private var folderName = ""
    @State private var selectedColor = "blue"
    
    let colors = ["blue", "red", "green", "orange", "purple"]
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Folder Name", text: $folderName)
                
                Picker("Color", selection: $selectedColor) {
                    ForEach(colors, id: \.self) { color in
                        Text(color).tag(color)
                    }
                }
            }
            .navigationTitle("New Folder")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveFolder()
                    }
                    // optional: avoid empty folders
                    .disabled(folderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func saveFolder() {
        let trimmedName = folderName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        // Create folder in Firestore via the view model
        foldersViewModel.addFolder(name: trimmedName)
        // (color is currently not persisted anywhere; see note below)
        
        dismiss()
    }
}
