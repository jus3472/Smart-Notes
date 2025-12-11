# 📱 Smart Note: Technical Deep Dive & Code Walkthrough

> **Team:** Ken Ryu, Justin Jiang, Yuna Shin, Sean Baek  
> **Goal:** An intelligent note-taking app featuring Audio Recording, AI Summarization, and Organized Management.

This document outlines the **User Flow** of the project, detailing **Individual Contributions** and the **Technical Implementation** of core features. It is designed to demonstrate our architectural decisions without opening the codebase directly.

---

## 1. 👥 Team & Contributions

| Member | Key Contributions |
| :--- | :--- |
| **Ken Ryu**<br>(jryu53) | • **Audio Engine:** Built underlying recording logic & UI (`AVAudioEngine`).<br>• **Backend:** Integrated Firebase Authentication & Configured Security Rules.<br>• **AI Integration:** Developed the converter function to display Gemini API–generated summary notes. |
| **Justin Jiang**<br>(jjiang295) | • **Data Logic:** Implemented **Soft Delete** and trash support.<br>• **Folder Mgmt:** Refined folder list layout & fixed creation logic.<br>• **UX:** Implemented Splash Screen & Settings View (Account, Sign Out).<br>• **Editing:** Enabled editing for existing notes & choosing folders for AI notes. |
| **Yuna Shin**<br>(yshin83) | • **AI Prompting:** Summarization & Action-item extraction using Gemini API.<br>• **Note Modes:** Implemented **Full Transcript Mode** (Diarization) & **Summary-Only Mode**.<br>• **Stability:** Fixed transcript loss issues after pause/resume.<br>• **UI Components:** Refactored `NoteRowView` to display tags and timestamps. |
| **Sean Baek**<br>(baek27) | • **Design:** Created User Flow, Wireframes, App Design, Poster, and Logo.<br>• **Auth UI:** Implemented Welcome, Login, and SignUp pages.<br>• **Main UI:** Implemented Main Page, **FAB** (Floating Action Button), and Search Bar.<br>• **Routing:** Implemented Recently Deleted Folder & routed deleted items to it.<br>• **Media:** Created the Demo Video. |

---

## 2. 🔐 Authentication & Onboarding
**Contributors:** Sean Baek (UI/UX), Ken Ryu (Backend), Justin Jiang (Splash)

We combined a visually engaging UI with robust authentication logic to ensure a secure and smooth entry point.

### A. Splash & User Flow (Justin & Sean)
Upon launch, the app displays a **Splash Screen** (implemented by **Justin**) before transitioning to the **Auth Flow** designed by **Sean**, which utilizes vector wave assets and smooth keyboard offset animations.

### B. Firebase Auth & Architecture (Ken)
Instead of simple view pushing, **Ken** implemented a `RootView` that listens to the `AuthViewModel`. This allows the app to dynamically switch the entire view hierarchy based on the authentication state.

**💻 Code Highlight: Root View Logic**
```swift
// RootView.swift (Implemented by Ken)
struct RootView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        // Dynamically switch the entire view hierarchy based on auth state.
        // This ensures the MainAppView is only loaded when authenticated.
        if authViewModel.isLoggedIn {
            MainAppView()
        } else {
            AuthView() // Sean's UI Implementation
        }
    }
}
```

## 3. 🏠 Main Dashboard & Organization
**Contributors:** Sean Baek (UI Structure), Justin Jiang (Folder Logic)

### A. Main Layout & FAB (Sean)
**Sean** implemented the **Floating Action Button (FAB)** and **Search Bar** logic, ensuring critical actions (Record, Create Folder) are always accessible.

**💻 Code Highlight: FAB Implementation**
```swift
// FoldersListView.swift (Implemented by Sean)
private var fabStack: some View {
    VStack(spacing: 14) {
        if isFabExpanded {
            // Button to trigger Recording View
            Button { activeSheet = .recording } label: {
                Image("FAB_record").resizable()
            }
        }
        // Main Toggle Button
        Button { withAnimation { isFabExpanded.toggle() } } label: {
            Image(isFabExpanded ? "FAB_cancel" : "FAB_default")
        }
    }
}
```
### B. Folder Sync & AI Routing (Justin)
**Justin** refined the folder list layout to support real-time synchronization and added logic to allow users to choose specific folders when saving AI-generated notes.
```swift
// FoldersViewModel.swift (Implemented by Justin)
private func ensureDefaultNotesFolderIfNeeded(uid: String, currentFolders: [SNFolder]) {
    // Prevent duplicate "Notes" folders
    if currentFolders.contains(where: { $0.name == "Notes" }) { return }
    
    // Automatically create default folder if missing
    service.addFolder(uid: uid, name: "Notes")
}
```

## 4. 🎙️ Core Feature: Recording Engine
**Contributors:** Ken Ryu (Audio Logic), Yuna Shin (Stability)

### A. Real-time Audio Capture (Ken)
Instead of using a standard recorder, **Ken** utilized `AVAudioEngine`'s `installTap`. This approach intercepts raw audio buffers, enabling **real-time waveform visualization** and simultaneous **Speech-to-Text (STT)** processing.

**💻 Code Highlight: Audio Tap Logic**
```swift
// LiveSpeechRecorderService.swift (Implemented by Ken)
inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
    // 1. Send buffer to Speech Recognizer for real-time STT
    self.recognitionRequest?.append(buffer)
    
    // 2. Write to Audio File (M4A) for playback
    try? self.audioFile?.write(from: buffer)
    
    // 3. Calculate Audio Level (RMS) for Waveform UI
    self.updateAudioLevel(from: buffer)
}
```
### B. Transcript Stability Fix (Yuna)

**Yuna** identified and fixed a critical bug where the transcript would reset when the recording was paused and resumed.
**💻 Code Highlight: Pause/Resume Logic
```swift
// LiveSpeechRecorderService.swift (Fixed by Yuna)
func pause() {
    // Securely backup the currently visible text to accumulatedText
    accumulatedText = transcribedText 
    isPaused = true
}

func resume() {
    isResuming = true 
    // On resume, append new text to the accumulated history
    // Logic: self.transcribedText = self.accumulatedText + " " + newText
}
```

## 5. 🧠 AI Intelligence: Gemini Integration
**Contributors:** Yuna Shin (Prompt Engineering), Ken Ryu (API Converter)

### A. Prompt Engineering (Yuna)
**Yuna** engineered specific prompts to ensure Gemini returns structured data suitable for our UI, rather than unstructured text. This includes **Summarization**, **Action Item Extraction**, and **Speaker Diarization**.

**💻 Code Highlight: Summarization Prompt**
```swift
// GeminiService.swift (Designed by Yuna)
let prompt = """
You are SmartNotes.
Task: Create a **very concise study summary**.
Requirements:
- Focus ONLY on the 3–6 most important ideas.
- Return the result as plain Markdown bullet points.
- Extract Action Items starting with '✅ Action Items:'.
"""
```
### B. API Response Converter (Ken)

Ken developed a converter function that parses the raw Markdown response from Gemini and formats it into the clean UI components displayed in the app.

**💻 Code Highlight: Markdown to UI Converter
```swift
// DetailNoteView.swift (Implemented by Ken)
private func buildSummarySections(from rawSummary: String) -> [SummarySection] {
    // 1. Clean up AI introductory text ("Here's a summary...")
    var text = rawSummary
        .replacingOccurrences(of: "Here's a summary...", with: "")
        .trimmingCharacters(in: .whitespacesAndNewlines)

    // 2. Parse Markdown line-by-line into UI Structs
    let lines = text.split(whereSeparator: \.isNewline)
    
    for line in lines {
        if line.hasPrefix("### ") { 
            // Detect Header -> Create New Section 
            flushSection()
        } else if line.hasPrefix("- ") {
            // Detect Bullet -> Add to Current Section
            currentBullets.append(cleanBullet)
        }
    }
    return sections // Returns structured data ready for SwiftUI
}
```

## 6. 📝 Note Visualization & Management
**Contributors:** Yuna Shin (Dynamic UI), Justin Jiang (Soft Delete), Sean Baek (Routing)

### A. Dynamic View Modes (Yuna)
**Yuna** implemented a `ViewBuilder` strategy to render different UIs based on the note type: **Full Transcript Mode** (Chat-bubble style with diarization) vs. **Summary-Only Mode** (Card style).

**💻 Code Highlight: Dynamic ViewBuilder**
```swift
// DetailNoteView.swift (Implemented by Yuna)
@ViewBuilder
var body: some View {
    if isFullTranscriptNote {
        // Render Speaker Diarization UI (Speaker: Professor/Student)
        diarizedContentView 
    } else {
        // Render Summary & Action Item Cards
        summaryNoteView
    }
}
```
### B. Soft Delete & Trash Support (Justin & Sean)

**Justin** implemented a **Soft Delete** mechanism. Instead of permanently deleting data, an isDeleted flag is set. Sean then routed these notes to a "Recently Deleted" folder, allowing for restoration.

**💻 Code Highlight: Soft Delete Logic
```swift
// NotesViewModel.swift (Implemented by Justin)
func delete(_ note: SNNote) {
    var updated = note
    updated.isDeleted = true       // Set flag instead of removing from DB
    updated.deletedAt = Date()     // Record deletion time
    updated.folderId = nil         // Detach from current folder
    
    // Sean's UI logic filters these notes into the 'Recently Deleted' view
    service.updateNote(note: updated)
}
```
## 7. 🎬 Final Demo
**Created by:** Sean Baek  
[Link to Demo Video](https://drive.google.com/file/d/1ScaqaO8YTX9g4ove1Pc0ZGQh64AkmKWz/view?usp=sharing)
