//
//  PeopleView.swift
//  Notes to self
//
//  Created by AI Assistant on 9/30/25.
//

import SwiftUI

// 📗 People View: List view of entries with edit functionality
struct PeopleView: View {
    @EnvironmentObject var store: NotesStore
    @State private var selectedNote: Note?
    
    var body: some View {
        NavigationView {
            Group {
                    if store.people.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Image(systemName: "person.2")
                            .font(.system(size: 64))
                            .foregroundColor(AppColors.secondaryText)
                        
                        Text("No People Yet")
                            .font(.title2)
                            .foregroundColor(AppColors.secondaryText)
                        
                        Text("Add some entries to see them here")
                            .font(.body)
                            .foregroundColor(AppColors.tertiaryText)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // List of entries
                    List(store.people) { note in
                        PeopleRowView(note: note)
                            .onTapGesture {
                                selectedNote = note
                            }
                    }
                    .listStyle(PlainListStyle())
                    .background(AppColors.listBackground)
                }
            }
            .background(AppColors.background)
            .navigationTitle("People")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: createNewEntry) {
                        Image(systemName: "plus")
                            .foregroundColor(AppColors.accent)
                    }
                }
            }
            .sheet(item: $selectedNote) { note in
                PeopleEditView(note: note)
                    .environmentObject(store)
            }
        }
    }
    
    private func createNewEntry() {
        // Create a new empty note and open it for editing
        let newNote = Note(text: "")
        selectedNote = newNote
    }
}

// 📗 People Row View: Individual row showing entry title
struct PeopleRowView: View {
    let note: Note
    
    private var title: String {
        // Get first line of text as title
        let lines = note.text.components(separatedBy: .newlines)
        return lines.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? note.text
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(AppColors.noteText)
                    .lineLimit(1)
                
                Text(DateFormatter.peopleFormatter.string(from: note.date))
                    .font(.caption)
                    .foregroundColor(AppColors.secondaryText)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(AppColors.tertiaryText)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

// 📗 People Edit View: Slide-in edit interface
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
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                // Title section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Edit Entry")
                        .font(.headline)
                        .foregroundColor(AppColors.noteText)
                    
                    Text("Created: \(DateFormatter.peopleFormatter.string(from: note.date))")
                        .font(.caption)
                        .foregroundColor(AppColors.secondaryText)
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Text editor
                TextEditor(text: $editedText)
                    .font(.body)
                    .foregroundColor(AppColors.noteText)
                    .padding(.horizontal)
                    .background(AppColors.background)
                
                Spacer()
            }
            .background(AppColors.background)
            .navigationTitle("Edit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                        dismiss()
                    }
                    .disabled(editedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
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
    PeopleView()
        .environmentObject(NotesStore())
}

