import SwiftUI
import FirebaseCore

@main
struct SmartNotesApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @State private var showSplash = true
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashView(showSplash: $showSplash)
                } else {
                    RootView()
                }
            }
            .environmentObject(authViewModel)
        }
    }
}
