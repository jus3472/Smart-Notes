// Features/Folders/Views/FolderDetailView.swift
import SwiftUI

struct FolderDetailView: View {
    let folder: Folder
    
    var body: some View {
        List {
            Text("Notes in \(folder.name ?? "Untitled")")
        }
        .navigationTitle(folder.name ?? "Folder")
    }
}
