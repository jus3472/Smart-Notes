# 📱 Smart Note: Final Code Walkthrough
> **Team:** Ken Ryu, Justin Jiang, Yuna Shin, Sean Baek  
> **Goal:** An intelligent note-taking app featuring Audio Recording, AI Summarization, and Organized Management.

This document outlines the **User Flow** and highlights the **Key Contributors** and **Code Components** for each feature.

---

## 1. 🚀 Onboarding
**Flow:** Splash → Welcome → Login/SignUp → Main View

### A. Splash Screen
- **Contributor:** **Justin Jiang**
- **Feature:** App entry animation with logo scaling and rotation effects.
- **File:** `SplashView.swift` [Link]

### B. Auth UI
- **Contributor:** **Sean Baek**
- **Feature:**
  - Implemented visually appealing UI using Wave vectors.
  - Handled keyboard interactions with smooth offset animations.
- **Files:**
  - `WelcomeScreen.swift` [Link]
  - `LoginScreen.swift` [Link]
  - `SignUpScreen.swift` [Link]

### C. Authentication Logic
- **Contributor:** **Ken Ryu**
- **Feature:** Firebase Auth SDK integration and session state management.
- **Files:**
  - `AuthViewModel.swift` [Link]
  - `RootView.swift` [Link] (Routing based on login state)

---

## 2. 🏠 Main Dashboard
**Flow:** Folder List → Search → FAB Action

### A. Main List & UI Structure
- **Contributor:** **Sean Baek**
- **Feature:**
  - Main layout containing the Search Bar and Floating Action Button (FAB).
  - Modal sheet management (`activeSheet`) for Settings and Recording.
- **File:** `FoldersListView.swift` [Link]

### B. Folder Management Logic
- **Contributor:** **Justin Jiang**
- **Feature:**
  - Real-time folder synchronization using Firestore listeners.
  - Logic to ensure the default "Notes" folder exists.
- **File:** `FoldersViewModel.swift` [Link]

---

## 3. 🎙️ Recording & AI
**Flow:** Record → STT → Gemini Processing → Save

### A. Real-time Recording Engine
- **Contributor:** **Ken Ryu**
- **Feature:**
  - Real-time speech-to-text service using `AVAudioEngine`.
  - Background audio handling and file persistence in `LiveSpeechRecorderService`.
- **Files:**
  - `LiveSpeechRecorderService.swift` [Link]
  - `RecordingViewModel.swift` [Link]

### B. AI Integration (Gemini API)
- **Contributor:** **Yuna Shin** & **Ken Ryu**
- **Feature (Yuna):**
  - **Prompt Engineering**: Designed prompts for summarization, tagging, and speaker diarization.
  - Implemented logic for `extractTags` and `diarize`.
- **Feature (Ken):**
  - Networking logic and JSON parsing for the Gemini API.
  - `generateSummaryAndSave`: Async function to process and save AI results to Firestore.
- **File:** `GeminiService.swift` [Link]

---

## 4. 📝 Note Details
**Flow:** View Detail → Edit → Move/Delete

### A. Dynamic Note View (Summary vs Transcript)
- **Contributor:** **Yuna Shin**
- **Feature:**
  - **Diarization View**: Chat-bubble UI distinguishing speakers (Professor vs. Student).
  - **Summary View**: Cards layout for AI-generated Summaries and Action Items.
- **Files:**
  - `DetailNoteView.swift` [Link]
  - `NoteRowView.swift` [Link]

### B. Note Management (Edit & Soft Delete)
- **Contributor:** **Justin Jiang**
- **Feature:**
  - Logic for editing content and moving notes between folders.
  - **Soft Delete**: Implemented "Trash" functionality using the `isDeleted` flag.
- **Files:**
  - `NotesViewModel.swift` [Link]
  - `RecentlyDeletedNotesView.swift` [Link]

---

## 5. ⚙️ Settings & Data
**Flow:** Settings → Sign Out

### A. Settings & Account
- **Contributor:** **Justin Jiang**
- **Feature:** User profile display, app version info, and sign-out functionality.
- **File:** `SettingsView.swift` [Link]

### B. Firestore Service (Backend)
- **Contributor:** **Ken Ryu**
- **Feature:** Centralized service for all CRUD operations and Firebase Storage uploads.
- **File:** `FirebaseNoteService.swift` [Link]
