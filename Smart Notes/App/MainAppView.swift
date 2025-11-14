// MainAppView.swift
import SwiftUI

struct MainAppView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var notesViewModel = NotesViewModel()
    
    var body: some View {
        TabView {
            FoldersListView()
                .tabItem {
                    Label("Notes", systemImage: "note.text")
                }
                .environmentObject(notesViewModel)
            
            RecordingView()
                .tabItem {
                    Label("Record", systemImage: "mic.fill")
                }

            VStack {
                Text("Settings")
                Button("Sign Out") {
                    authViewModel.signOut()
                }
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
        }
    }
}
