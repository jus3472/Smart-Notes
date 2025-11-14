// RootView.swift
import SwiftUI

struct RootView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        Group {
            if authViewModel.isLoggedIn {
                MainAppView()
            } else {
                AuthView()
            }
        }
    }
}
