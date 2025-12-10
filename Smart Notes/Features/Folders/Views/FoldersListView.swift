import SwiftUI

struct FoldersListView: View {
    @StateObject private var foldersViewModel = FoldersViewModel()
    @EnvironmentObject var notesViewModel: NotesViewModel

    // FAB state
    @State private var isFabExpanded = false

    // Which sheet is showing (recording / settings)
    private enum ActiveSheet: Identifiable {
        case recording, settings
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
    private var isKeyboardActive: Bool {
        isSearchFocused
    }

    // Delete confirmation state
    @State private var folderToDelete: SNFolder?
    @State private var isShowingDeleteAlert = false

    // New folder overlay
    @State private var showAddFolder = false

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
                            RecentlyDeletedNotesView()
                        } label: {
                            Label("Recently Deleted", systemImage: "trash")
                        }
                    } header: {
                        Text("Primary")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                    }

                    // MARK: Folder list (excluding default "Notes" folder)
                    Section {
                        ForEach(visibleFolders) { folder in
                            let isProtected = isProtectedFolder(folder)

                            HStack {
                                NavigationLink {
                                    FolderDetailView(folder: folder)
                                } label: {
                                    Label(folder.name, systemImage: "folder")
                                }

                                if isEditingFolders {
                                    Spacer()
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
                            .deleteDisabled(true)
                        }
                        .onMove { indices, offset in
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
            .environment(\.editMode,
                         .constant(isEditingFolders ? EditMode.active : EditMode.inactive))

            // -------- CUSTOM NAVIGATION BAR WITH LOGO --------
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                // CENTER LOGO (PNG)
                ToolbarItem(placement: .principal) {
                    HStack {
                        Image("smart_notes_logo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 55)
                        Spacer(minLength: 0)
                    }
                    .padding(.leading, -8)
                }

                // GEAR ICON (right side)
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
            // -------------------------------------------------

            .safeAreaInset(edge: .bottom) {
                // hide search bar + FAB while overlay is visible
                if !showAddFolder {
                    bottomBarWithSearchAndFab
                }
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .recording:
                    RecordingView()
                case .settings:
                    SettingsView()
                }
            }
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
            // Overlay for creating folder
            .overlay {
                if showAddFolder {
                    AddFolderOverlayView(isPresented: $showAddFolder)
                        .environmentObject(foldersViewModel)
                        .transition(.opacity)
                        .animation(.easeInOut, value: showAddFolder)
                }
            }
        }
        .onAppear { collapseFab() }
    }

    // MARK: - Protected folder logic

    private func isProtectedFolder(_ folder: SNFolder) -> Bool {
        folder.name == "Notes"
    }

    // MARK: - Delete helpers

    private func performConfirmedDelete(folder: SNFolder) {
        guard !isProtectedFolder(folder),
              let index = foldersViewModel.folders.firstIndex(where: { $0.id == folder.id })
        else { return }

        notesViewModel.deleteNotes(inFolder: folder)

        let set = IndexSet(integer: index)
        foldersViewModel.deleteFolder(at: set)
    }

    // MARK: - FAB

    private var fabStack: some View {
        VStack(spacing: 14) {
            if isFabExpanded {
                Button {
                    collapseFab()
                    showAddFolder = true   // show overlay
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
            .padding(.horizontal, 12)
            .padding(.vertical, 13)
            .background(Color(.systemGray5))
            .clipShape(Capsule())
            // expand when keyboard up
            .frame(
                maxWidth: isKeyboardActive ? .infinity : 260,
                alignment: .leading
            )
            .animation(.easeOut(duration: 0.2), value: isKeyboardActive)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, isKeyboardActive ? 20 : 3)
        .contentShape(Rectangle())
        .onTapGesture { collapseFab() }

        return searchBar
            .background(.ultraThinMaterial)
            .overlay(
                Group {
                    // hide FAB while keyboard active
                    if !isKeyboardActive {
                        fabStack
                            .padding(.trailing, 16)
                            .padding(.bottom, -15)
                    }
                },
                alignment: .bottomTrailing
            )
    }

    // MARK: - Helper

    private func collapseFab() {
        if isFabExpanded {
            withAnimation(.spring()) { isFabExpanded = false }
        }
    }
}

// MARK: - New Folder Overlay

struct AddFolderOverlayView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var foldersViewModel: FoldersViewModel

    @State private var folderName: String = ""
    @FocusState private var isTextFocused: Bool

    var body: some View {
        ZStack {
            // dimmed background
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }

            VStack(spacing: 20) {
                Text("New Folder")
                    .font(.title3.weight(.semibold))

                TextField("Folder name", text: $folderName)
                    .focused($isTextFocused)
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray5))
                    .cornerRadius(16)
                    .frame(maxWidth: 280)

                HStack(spacing: 16) {
                    Button {
                        isPresented = false
                    } label: {
                        Text("Cancel")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray4))
                            .foregroundColor(.white)
                            .cornerRadius(14)
                    }

                    Button {
                        createFolder()
                    } label: {
                        Text("Create")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue)   // blue confirm button
                            .foregroundColor(.white)
                            .cornerRadius(14)
                    }
                    .disabled(folderName.trimmingCharacters(in: .whitespaces).isEmpty)
                    .opacity(folderName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
                }
                .frame(maxWidth: 280)
            }
            .padding(.vertical, 32)
            .padding(.horizontal, 24)
            .background(Color.white)
            .cornerRadius(32)
            .shadow(radius: 20)
        }
        .onAppear {
            // focus text field when overlay appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isTextFocused = true
            }
        }
    }

    private func createFolder() {
        let trimmed = folderName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        foldersViewModel.addFolder(name: trimmed)
        isPresented = false
    }
}

// MARK: - Recently Deleted Notes View + Read-only Detail

struct RecentlyDeletedNotesView: View {
    @EnvironmentObject var notesViewModel: NotesViewModel

    private var deletedNotes: [SNNote] {
        notesViewModel.deletedNotes
    }

    var body: some View {
        Group {
            if deletedNotes.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "trash")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text("No recently deleted notes")
                        .font(.headline)
                    Text("Deleted notes will appear here for now.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.top, 80)
            } else {
                List {
                    ForEach(deletedNotes) { note in
                        NavigationLink {
                            DeletedNoteDetailView(note: note)
                        } label: {
                            NoteRowView(note: note, showStar: false)
                        }
                        .swipeActions(edge: .trailing) {
                            Button("Restore") {
                                notesViewModel.restore(note)
                            }.tint(.green)

                            Button("Delete", role: .destructive) {
                                notesViewModel.deleteForever(note)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Recently Deleted")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct DeletedNoteDetailView: View {
    let note: SNNote
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(note.title)
                    .font(.largeTitle.bold())

                if let deletedAt = note.deletedAt {
                    Text("Deleted: \(deletedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                Divider()
                Text(note.content)
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FoldersListView_Previews: PreviewProvider {
    static var previews: some View {
        FoldersListView()
            .environmentObject(NotesViewModel())
    }
}
