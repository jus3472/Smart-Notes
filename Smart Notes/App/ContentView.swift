//
//  ContentView.swift
//  Smart Notes
//
//  Created by Justin Jiang on 11/3/25.
//
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            FoldersListView()
                .tabItem {
                    Label("Folders", systemImage: "folder.fill")
                }
            
            RecordingView()
                .tabItem {
                    Label("Record", systemImage: "mic.fill")
                }
        }
    }
}

#Preview {
    ContentView()
}
