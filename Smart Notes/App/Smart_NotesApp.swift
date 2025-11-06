//
//  Smart_NotesApp.swift
//  Smart Notes
//
//  Created by Justin Jiang on 11/3/25.
//

import SwiftUI

@main
struct Smart_NotesApp: App {
    // 1. PersistenceController 인스턴스 생성
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                // 2. ✅ 이 코드를 추가하여 viewContext를 환경 변수로 주입합니다.
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
