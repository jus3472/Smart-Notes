// HomeView.swift
import SwiftUI
import CoreData

struct HomeView: View {
    
    // 1. @FetchRequest 프로퍼티 선언
    // 이 프로퍼티 래퍼가 Core Data의 변경 사항을 자동으로 감지하여 뷰를 새로고침합니다.
    @FetchRequest private var recentNotes: FetchedResults<Note>

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Recent Notes").font(.headline)) {
                    ForEach(recentNotes) { note in
                        NavigationLink(destination: NoteEditorView(note: note)) {
                            CoreDataNoteRowView(note: note)
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Smart Notes")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // 설정 화면으로 이동
                    }) {
                        Image(systemName: "gear")
                    }
                }
            }
        }
    }
    
    // 2. init() 메서드에서 Fetch Request를 수동으로 구성
    init() {
        // 3. NSFetchRequest 객체 생성
        let request: NSFetchRequest<Note> = Note.fetchRequest()
        
        // 4. 정렬 순서 설정 (가장 최근에 수정된 순서)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Note.updatedAt, ascending: false)
        ]
        
        // 5. 'fetchLimit' (10개) 설정
        request.fetchLimit = 10
        
        // 6. 위에서 만든 request로 _recentNotes 프로퍼티 래퍼를 초기화
        _recentNotes = FetchRequest(
            fetchRequest: request,
            animation: .default
        )
    }
}
