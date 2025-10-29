//
//  PeopleEditView.swift
//  Notes to self
//
//  Created by AI Assistant on 10/29/25.
//

import SwiftUI

// 📗 People Edit View: Navigation-style edit interface for people entries
struct PeopleEditView: View {
    @EnvironmentObject var store: NotesStore
    @Environment(\.dismiss) private var dismiss
    let note: Note
    @State private var editedText: String
    
    init(note: Note) {
        self.note = note
        self._editedText = State(initialValue: note.text)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Date info section
            VStack(alignment: .leading, spacing: 8) {
                Text("Created: \(DateFormatter.peopleFormatter.string(from: note.date))")
                    .font(.caption)
                    .foregroundColor(AppColors.secondaryText)
                    .padding(.horizontal)
                    .padding(.top)
            }
            
            // Text editor
            TextEditor(text: $editedText)
                .font(.body)
                .foregroundColor(AppColors.noteText)
                .scrollContentBackground(.hidden)
                .background(AppColors.inputBackground)
                .padding(.horizontal)
            
            Spacer()
        }
        .background(AppColors.background)
        .navigationTitle(note.text.isEmpty ? "New Person" : "Edit Person")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
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
    
    private func saveChanges() {
        let trimmedText = editedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        if let index = store.people.firstIndex(where: { $0.id == note.id }) {
            // Update existing person
            let updatedNote = Note(
                id: note.id,
                text: trimmedText,
                date: note.date,
                lastModified: Date()
            )
            store.people[index] = updatedNote
        } else {
            // Add new person (for + button created entries)
            let newNote = Note(
                id: note.id,
                text: trimmedText,
                date: Date(),
                lastModified: Date()
            )
            store.people.insert(newNote, at: 0)
        }
    }
}

// MARK: - Date Formatter Extension
extension DateFormatter {
    static let peopleFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

#Preview {
    NavigationView {
        PeopleEditView(note: Note(text: "Sample person"))
            .environmentObject(NotesStore())
    }
}

