// SmartNotesApp.swift
import SwiftUI
import FirebaseCore

@main
struct SmartNotesApp: App {
    // 앱 전체에서 공유할 AuthViewModel
    @StateObject private var authViewModel = AuthViewModel()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authViewModel)
        }
    }
}
