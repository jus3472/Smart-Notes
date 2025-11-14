import SwiftUI

struct FoldersListView: View {
    @StateObject private var foldersViewModel = FoldersViewModel()
    @EnvironmentObject var notesViewModel: NotesViewModel
    
    @State private var showingAddFolder = false
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink(destination: FolderDetailView(folder: nil)) {
                        Label("All Notes", systemImage: "tray.full")
                    }
                }
                
                Section("Folders") {
                    ForEach(foldersViewModel.folders) { folder in
                        NavigationLink(destination: FolderDetailView(folder: folder)) {
                            Text(folder.name)
                        }
                    }
                    .onDelete(perform: foldersViewModel.deleteFolder)
                }
            }
            .navigationTitle("Folders")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddFolder = true
                    }) {
                        Image(systemName: "folder.badge.plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddFolder) {
                AddFolderView()
                    .environmentObject(foldersViewModel)
            }
        }
    }
}
