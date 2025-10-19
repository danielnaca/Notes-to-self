//
//  EntriesView.swift
//  Notes to self
//
//  Created by AI Assistant on 9/30/25.
//

import SwiftUI

// 📗 Entries View: List-based entries interface with sheet editing
struct EntriesView: View {
    @EnvironmentObject var store: NotesStore
    @State private var selectedNote: Note?
    
    var body: some View {
        NavigationView {
            Group {
                if store.notes.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Image(systemName: "note.text")
                            .font(.system(size: 64))
                            .foregroundColor(AppColors.secondaryText)
                        Text("No entries yet")
                            .font(.title2)
                            .foregroundColor(AppColors.secondaryText)
                        Text("Tap the + button to create your first entry")
                            .font(.body)
                            .foregroundColor(AppColors.tertiaryText)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // List of entries
                    List(store.notes) { note in
                        EntriesRowView(note: note)
                            .onTapGesture {
                                selectedNote = note
                            }
                    }
                    .listStyle(PlainListStyle())
                    .background(AppColors.listBackground)
                }
            }
            .background(AppColors.background)
            .navigationTitle("Entries")
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
                EntriesEditView(note: note)
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

#Preview {
    EntriesView()
        .environmentObject(NotesStore())
}

