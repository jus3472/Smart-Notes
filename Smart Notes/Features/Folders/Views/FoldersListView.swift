import SwiftUI

struct FoldersListView: View {
    @StateObject private var foldersViewModel = FoldersViewModel()
    @EnvironmentObject var notesViewModel: NotesViewModel
    
    @State private var showingAddFolder = false
    
    var body: some View {
        NavigationStack {
            List {
                // Smart / quick access section
                Section {
                    NavigationLink {
                        FolderDetailView(folder: nil)
                    } label: {
                        Label("Notes", systemImage: "tray.full")
                    }
                    
                    NavigationLink {
                        StarredNotesView()
                    } label: {
                        Label("Starred", systemImage: "star.fill")
                    }
                }
                
                // User-created Folders Section
                Section("Folders") {
                    ForEach(foldersViewModel.folders) { folder in
                        NavigationLink {
                            FolderDetailView(folder: folder)
                        } label: {
                            Text(folder.name)
                        }
                    }
                    .onDelete { indexSet in
                        foldersViewModel.deleteFolder(at: indexSet)
                    }
                }
            }
            .navigationTitle("Folders")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddFolder = true
                    } label: {
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
