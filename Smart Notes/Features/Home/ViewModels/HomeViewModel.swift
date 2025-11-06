import SwiftUI
import CoreData

class HomeViewModel: ObservableObject {
    @Published var recentNotes: [Note] = []
    private let context = PersistenceController.shared.container.viewContext
    
    init() {
        fetchRecentNotes()
    }
    
    func fetchRecentNotes() {
        let request: NSFetchRequest<Note> = Note.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Note.createdAt, ascending: false)]
        request.fetchLimit = 10
        
        do {
            recentNotes = try context.fetch(request)
        } catch {
            print("Error fetching notes: \(error)")
        }
    }
    
    func startQuickRecording() {
        // Recording View로 네비게이션
    }
}
