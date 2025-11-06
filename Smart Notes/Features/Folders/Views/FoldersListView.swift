import SwiftUI

struct FoldersListView: View {
    @StateObject private var viewModel = FoldersViewModel()
    @State private var showingAddFolder = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.folders) { folder in
                    NavigationLink(destination: FolderDetailView(folder: folder)) {
                        HStack {
                            Image(systemName: "folder.fill")
                                .foregroundColor(Color(folder.color ?? "blue"))
                            Text(folder.name ?? "Untitled")
                            Spacer()
                            // 관계 설정 후에는 아래 주석을 해제
                            // Text("\((folder.notes as? Set<Note>)?.count ?? 0)")
                            Text("0") // 임시 코드
                                .foregroundColor(.gray)
                        }
                    }
                }
                .onDelete(perform: viewModel.deleteFolder)
            }
            .navigationTitle("Folders")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddFolder = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddFolder) {
                AddFolderView()
            }
        }
    }
}
