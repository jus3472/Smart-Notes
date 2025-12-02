import SwiftUI

struct FoldersListView: View {
    @StateObject private var foldersViewModel = FoldersViewModel()
    @EnvironmentObject var notesViewModel: NotesViewModel

    // FAB state
    @State private var isFabExpanded = false

    // Which sheet is showing (add folder / recording / settings)
    private enum ActiveSheet: Identifiable {
        case addFolder, recording, settings
        var id: Int { hashValue }
    }
    @State private var activeSheet: ActiveSheet?

    // Edit Mode
    @State private var isEditingFolders = false

    // Search state
    @State private var searchText: String = ""
    @FocusState private var isSearchFocused: Bool
    private var isSearching: Bool {
        isSearchFocused || !searchText.isEmpty
    }

    // Recently Deleted (local list for now)
    @State private var recentlyDeletedFolders: [SNFolder] = []

    // Delete confirmation state
    @State private var folderToDelete: SNFolder?
    @State private var isShowingDeleteAlert = false

    // MARK: - Derived folder list (hide default "Notes" folder)
    private var visibleFolders: [SNFolder] {
        foldersViewModel.folders.filter { !isProtectedFolder($0) }
    }

    var body: some View {
        NavigationStack {
            List {
                if isSearching {
                    // ===== SEARCH MODE =====
                    let base = visibleFolders
                    let folders = searchText.isEmpty
                        ? base
                        : base.filter {
                            $0.name.localizedCaseInsensitiveContains(searchText)
                        }

                    Section(header: Text(searchText.isEmpty ? "Suggested" : "Results")) {
                        ForEach(folders) { folder in
                            NavigationLink {
                                FolderDetailView(folder: folder)
                            } label: {
                                Label(folder.name, systemImage: "folder")
                            }
                        }
                    }

                } else {
                    // ===== NORMAL MODE =====

                    // MARK: Primary section: Notes, Starred, Recently Deleted
                    Section {
                        NavigationLink {
                            FolderDetailView(folder: nil)
                        } label: {
                            Label("Notes", systemImage: "tray.full")
                        }

                        NavigationLink {
                            StarredNotesView()
                        } label: {
                            Label("Starred", systemImage: "star.fill")
                        }

                        NavigationLink {
                            RecentlyDeletedFoldersView(folders: recentlyDeletedFolders)
                        } label: {
                            Label("Recently Deleted", systemImage: "trash")
                        }
                    } header: {
                        Text("Primary")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                    }

                    // MARK: Main folders (excluding the default "Notes" folder)
                    Section {
                        ForEach(visibleFolders) { folder in
                            let isProtected = isProtectedFolder(folder)

                            HStack {
                                // Folder navigation
                                NavigationLink {
                                    FolderDetailView(folder: folder)
                                } label: {
                                    Label(folder.name, systemImage: "folder")
                                }

                                if isEditingFolders {
                                    Spacer()

                                    // Delete button on the right (NOT shown for protected "Notes")
                                    if !isProtected {
                                        Button(role: .destructive) {
                                            folderToDelete = folder
                                            isShowingDeleteAlert = true
                                        } label: {
                                            Image(systemName: "minus.circle.fill")
                                                .foregroundColor(.red)
                                                .imageScale(.large)
                                        }
                                        .buttonStyle(.borderless)
                                    }
                                }
                            }
                            .deleteDisabled(true)  // hide system left red minus
                        }
                        // Only use system move handle (no system delete)
                        .onMove { indices, offset in
                            // Move inside the full array using IDs
                            let ids = indices.map { visibleFolders[$0].id }
                            var all = foldersViewModel.folders
                            for id in ids {
                                if let from = all.firstIndex(where: { $0.id == id }) {
                                    let folder = all.remove(at: from)
                                    let to = min(offset, all.count)
                                    all.insert(folder, at: to)
                                }
                            }
                            foldersViewModel.folders = all
                        }

                    } header: {
                        HStack {
                            Text("Folders")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)

                            Spacer()

                            if !visibleFolders.isEmpty {
                                Button(isEditingFolders ? "Done" : "Edit") {
                                    withAnimation { isEditingFolders.toggle() }
                                }
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.15))
                                .foregroundColor(.blue)
                                .cornerRadius(10)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            // keep system move handle active but we control editing via our button
            .environment(\.editMode,
                         .constant(isEditingFolders ? EditMode.active : EditMode.inactive))
            .navigationTitle("Smart Notes")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        collapseFab()
                        activeSheet = .settings
                    } label: {
                        Image(systemName: "gearshape")
                            .imageScale(.large)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                bottomBarWithSearchAndFab
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .addFolder:
                    AddFolderView().environmentObject(foldersViewModel)
                case .recording:
                    RecordingView()
                case .settings:
                    SettingsView()
                }
            }
            // Delete confirmation
            .alert("Delete Folder?",
                   isPresented: $isShowingDeleteAlert,
                   presenting: folderToDelete) { folder in
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    performConfirmedDelete(folder: folder)
                }
            } message: { folder in
                Text("""
                Are you sure you want to delete "\(folder.name)"?
                All notes inside this folder will be moved to Recently Deleted.
                """)
            }
        }
        .onAppear {
            collapseFab()
        }
    }

    // MARK: - Protected folder logic

    /// "Notes" is the base folder and can never be deleted.
    private func isProtectedFolder(_ folder: SNFolder) -> Bool {
        folder.name == "Notes"
    }

    // MARK: - Delete helpers

    /// Called from the alert “Delete” button
    private func performConfirmedDelete(folder: SNFolder) {
        guard !isProtectedFolder(folder),
              let index = foldersViewModel.folders.firstIndex(where: { $0.id == folder.id })
        else { return }

        recentlyDeletedFolders.append(folder)
        let set = IndexSet(integer: index)
        foldersViewModel.deleteFolder(at: set)
    }

    // MARK: - FAB

    private var fabStack: some View {
        VStack(spacing: 14) {
            if isFabExpanded {
                Button {
                    collapseFab()
                    activeSheet = .addFolder
                } label: {
                    Image("FAB_create_folder")
                        .resizable()
                        .frame(width: 75, height: 75)
                        .shadow(radius: 6)
                }

                Button {
                    collapseFab()
                    activeSheet = .recording
                } label: {
                    Image("FAB_record")
                        .resizable()
                        .frame(width: 75, height: 75)
                        .shadow(radius: 6)
                }
            }

            Button {
                withAnimation(.spring()) {
                    isFabExpanded.toggle()
                }
            } label: {
                Image(isFabExpanded ? "FAB_cancel" : "FAB_default")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .shadow(radius: 6)
            }
        }
    }

    // MARK: - Search bar + FAB

    private var bottomBarWithSearchAndFab: some View {
        let searchBar = HStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)

                TextField("Search", text: $searchText)
                    .focused($isSearchFocused)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)

                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .frame(width: 260)
            .padding(.horizontal, 12)
            .padding(.vertical, 13)
            .background(Color(.systemGray5))
            .clipShape(Capsule())

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 3)
        .contentShape(Rectangle())
        .onTapGesture { collapseFab() }

        return searchBar
            .background(.ultraThinMaterial)
            .overlay(
                fabStack
                    .padding(.trailing, 16)
                    .padding(.bottom, -15),
                alignment: .bottomTrailing
            )
    }

    // MARK: - Helper

    private func collapseFab() {
        if isFabExpanded {
            withAnimation(.spring()) {
                isFabExpanded = false
            }
        }
    }
}

// MARK: - Recently Deleted Screen

struct RecentlyDeletedFoldersView: View {
    let folders: [SNFolder]

    var body: some View {
        List {
            if folders.isEmpty {
                Text("No recently deleted folders.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(folders) { folder in
                    Text(folder.name)
                }
            }
        }
        .navigationTitle("Recently Deleted")
    }
}

struct FoldersListView_Previews: PreviewProvider {
    static var previews: some View {
        FoldersListView()
            .environmentObject(NotesViewModel())
    }
}
