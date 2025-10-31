//
//  EntriesView.swift
//  Notes to self
//
//  Created by AI Assistant on 9/30/25.
//

import SwiftUI

// 📗 Entries View: Messages-style interface for quick entries
struct EntriesView: View {
    @EnvironmentObject var store: NotesStore
    @State private var newEntryText: String = ""
    @State private var keyboardHeight: CGFloat = 0
    @FocusState private var isInputFocused: Bool
    @State private var editingNoteId: UUID? = nil
    @State private var scrollProxy: ScrollViewProxy? = nil
    
    private var isEditMode: Bool {
        editingNoteId != nil
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Messages area
                ScrollViewReader { proxy in
                    ScrollView {
                        Color.clear.frame(height: 0).onAppear {
                            scrollProxy = proxy
                        }
                        VStack(spacing: 12) {
                            if store.notes.isEmpty {
                                // Empty state
                                VStack(spacing: 20) {
                                    Image(systemName: "note.text")
                                        .font(.system(size: 64))
                                        .foregroundColor(AppColors.secondaryText)
                                    Text("No entries yet")
                                        .font(.title2)
                                        .foregroundColor(AppColors.secondaryText)
                                    Text("Type a message below to create your first entry")
                                        .font(.body)
                                        .foregroundColor(AppColors.tertiaryText)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 100)
                            } else {
                                // Show entries in reverse order (newest at bottom)
                                ForEach(store.notes.reversed()) { note in
                                    EntryMessageBubble(note: note, isEditing: isEditMode && editingNoteId == note.id)
                                        .id(note.id)
                                        .opacity(isEditMode && editingNoteId != note.id ? 0 : 1.0)
                                        .onTapGesture {
                                            // Only allow editing when keyboard is closed
                                            if !isInputFocused {
                                                startEditing(note: note)
                                            }
                                        }
                                }
                            }
                        }
                        .padding()
                    }
                    .background(AppColors.background)
                    .disabled(isEditMode)
                    .contentShape(Rectangle())
                    .simultaneousGesture(
                        TapGesture().onEnded { _ in
                            // Dismiss keyboard and cancel edit when tapping messages area
                            if isEditMode {
                                cancelEditing()
                            } else {
                                isInputFocused = false
                            }
                        }
                    )
                    .onChange(of: store.notes.count) { _ in
                        // Scroll to bottom when new entry is added
                        if let lastNote = store.notes.first {
                            withAnimation {
                                proxy.scrollTo(lastNote.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Input Bar - fixed at bottom, moves with keyboard
                VStack(spacing: 0) {
                    ZStack(alignment: .bottomTrailing) {
                        TextField("New entry...", text: $newEntryText, axis: .vertical)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .padding(.trailing, 40) // Space for button
                            .background(AppColors.inputBackground)
                            .cornerRadius(20)
                            .focused($isInputFocused)
                            .lineLimit(1...5)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Button(action: sendEntry) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(newEntryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? AppColors.tertiaryText : AppColors.accent)
                        }
                        .disabled(newEntryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .padding(.trailing, 8)
                        .padding(.bottom, 6)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(AppColors.background)
                .padding(.bottom, keyboardHeight)
            }
            .ignoresSafeArea(.keyboard)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                setupKeyboardObservers()
            }
        }
    }
    
    private func sendEntry() {
        let trimmed = newEntryText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        if let editingId = editingNoteId {
            // Update existing note
            if let index = store.notes.firstIndex(where: { $0.id == editingId }) {
                let originalNote = store.notes[index]
                let updatedNote = Note(
                    id: originalNote.id,
                    text: trimmed,
                    date: originalNote.date,
                    lastModified: Date()
                )
                store.notes[index] = updatedNote
            }
            editingNoteId = nil
        } else {
            // Create new note
            let newNote = Note(text: trimmed)
            store.notes.insert(newNote, at: 0) // Store keeps newest first
        }
        
        newEntryText = ""
        isInputFocused = false // Dismiss keyboard
    }
    
    private func startEditing(note: Note) {
        editingNoteId = note.id
        newEntryText = note.text
        isInputFocused = true
        
        // Scroll the editing message to the top
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation {
                scrollProxy?.scrollTo(note.id, anchor: .top)
            }
        }
    }
    
    private func cancelEditing() {
        editingNoteId = nil
        newEntryText = ""
        isInputFocused = false
    }
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                withAnimation {
                    // Position Input Bar 80px lower for proper spacing
                    keyboardHeight = keyboardFrame.height - 80
                }
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { _ in
            withAnimation {
                keyboardHeight = 0
            }
        }
    }
}

// 📗 Entry Message Bubble: Individual entry in chat style
struct EntryMessageBubble: View {
    let note: Note
    let isEditing: Bool
    
    var body: some View {
        HStack {
            Text(note.text)
                .font(.body)
                .foregroundColor(AppColors.noteText)
            Spacer()
        }
        .padding(12)
        .background(isEditing ? Color.clear : AppColors.inputBackground)
        .cornerRadius(16)
    }
}

#Preview {
    EntriesView()
        .environmentObject(NotesStore())
}

