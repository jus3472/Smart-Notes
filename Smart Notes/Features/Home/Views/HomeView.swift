import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                // 최근 녹음 섹션
                VStack(alignment: .leading) {
                    Text("Recent Notes")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ScrollView {
                        ForEach(viewModel.recentNotes) { note in
                            NoteRowView(note: note)
                                .padding(.horizontal)
                        }
                    }
                }
                
                // 빠른 녹음 버튼
                Button(action: {
                    viewModel.startQuickRecording()
                }) {
                    Label("Quick Recording", systemImage: "mic.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }
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
}
