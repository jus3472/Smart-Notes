// Features/Folders/Views/AddFolderView.swift
import SwiftUI

struct AddFolderView: View {
    @Environment(\.dismiss) var dismiss
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
                }
            }
        }
    }
    
    func saveFolder() {
        let context = PersistenceController.shared.container.viewContext
        let newFolder = Folder(context: context)
        newFolder.id = UUID()
        newFolder.name = folderName
        newFolder.color = selectedColor
        newFolder.createdAt = Date()
        
        do {
            try context.save()
            dismiss()
        } catch {
            print("Error saving folder: \(error)")
        }
    }
}
