//
//  EntriesEditView.swift
//  Notes to self
//
//  Created by AI Assistant on 10/19/25.
//

import SwiftUI

// 📗 Entries Edit View: Sheet for creating/editing entries
struct EntriesEditView: View {
    @EnvironmentObject var store: NotesStore
    @Environment(\.dismiss) private var dismiss
    
    let note: Note
    @State private var editedText: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Text editor
                TextEditor(text: $editedText)
                    .scrollContentBackground(.hidden)
                    .background(AppColors.inputBackground)
                    .foregroundColor(AppColors.noteText)
                    .padding()
                    .onAppear {
                        editedText = note.text
                        // Configure text appearance
                        UITextView.appearance().backgroundColor = UIColor(AppColors.inputBackground)
                        UITextView.appearance().textColor = UIColor(AppColors.noteText)
                    }
                
                Spacer()
            }
            .background(AppColors.background)
            .navigationTitle(note.text.isEmpty ? "New Entry" : "Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.accent)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                        dismiss()
                    }
                    .foregroundColor(AppColors.accent)
                    .disabled(editedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func saveChanges() {
        let trimmedText = editedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        if let index = store.notes.firstIndex(where: { $0.id == note.id }) {
            // Update existing entry
            let updatedNote = Note(
                id: note.id,
                text: trimmedText,
                date: note.date,
                lastModified: Date()
            )
            store.notes[index] = updatedNote
        } else {
            // Add new entry (for + button created entries)
            let newNote = Note(
                id: note.id,
                text: trimmedText,
                date: Date(),
                lastModified: Date()
            )
            store.notes.insert(newNote, at: 0)
        }
    }
}

#Preview {
    @Previewable @State var sampleNote = Note(text: "Sample entry text")
    EntriesEditView(note: sampleNote)
        .environmentObject(NotesStore())
}

