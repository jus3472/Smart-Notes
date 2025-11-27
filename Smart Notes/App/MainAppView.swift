// MainAppView.swift
import SwiftUI

struct MainAppView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var notesViewModel = NotesViewModel()
    
    var body: some View {
        NavigationStack {
            FoldersListView()        // <- main screen
        }
        .environmentObject(notesViewModel)
    }
}
