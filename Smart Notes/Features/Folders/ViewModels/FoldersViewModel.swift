// Features/Folders/ViewModels/FoldersViewModel.swift
import SwiftUI
import CoreData

class FoldersViewModel: ObservableObject {
    @Published var folders: [Folder] = []
    private let context = PersistenceController.shared.container.viewContext
    
    init() {
        fetchFolders()
    }
    
    func fetchFolders() {
        let request: NSFetchRequest<Folder> = Folder.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Folder.createdAt, ascending: false)]
        
        do {
            folders = try context.fetch(request)
        } catch {
            print("Error fetching folders: \(error)")
        }
    }
    
    func deleteFolder(at offsets: IndexSet) {
        for index in offsets {
            let folder = folders[index]
            context.delete(folder)
        }
        
        do {
            try context.save()
            fetchFolders()
        } catch {
            print("Error deleting folder: \(error)")
        }
    }
}
