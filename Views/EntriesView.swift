//
//  EntriesView.swift
//  Notes to self
//
//  Created by AI Assistant on 9/30/25.
//

import SwiftUI

// 📗 Entries View: Main notes interface (formerly ContentView content)
struct EntriesView: View {
    @EnvironmentObject var store: NotesStore
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Input section
                HStack {
                    ExpandingTextView(
                        text: $store.newNote, 
                        placeholder: "What's on your mind?",
                        onSubmit: {
                            if store.isEditing {
                                store.updateNote()
                            } else {
                                store.addNote()
                            }
                        }
                    )
                    .focused($isInputFocused)
                        .frame(minHeight: 44)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(AppColors.inputBackground)
                        .cornerRadius(22)
                    
                    Button(action: {
                        if store.isEditing {
                            store.updateNote()
                        } else {
                            store.addNote()
                        }
                    }) {
                        Image(systemName: store.isEditing ? "checkmark.circle.fill" : "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(AppColors.accent)
                    }
                    .disabled(store.newNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
                .background(AppColors.background)
                
                // Notes list
                if store.notes.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "note.text")
                            .font(.system(size: 48))
                            .foregroundColor(AppColors.secondaryText)
                        Text("No notes yet")
                            .font(.title2)
                            .foregroundColor(AppColors.secondaryText)
                        Text("Add your first note above")
                            .font(.body)
                            .foregroundColor(AppColors.tertiaryText)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(store.notes) { note in
                            NoteItemView(note: note)
                                .onTapGesture {
                                    // Check if keyboard was open before dismissing
                                    let wasKeyboardOpen = isInputFocused
                                    
                                    // Dismiss keyboard
                                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                    isInputFocused = false
                                    
                                    // Only start editing if keyboard wasn't open
                                    if !wasKeyboardOpen {
                                        store.startEditing(note: note)
                                    }
                                }
                        }
                        .onDelete(perform: store.delete)
                    }
                    .listStyle(PlainListStyle())
                    .background(AppColors.listBackground)
                }
            }
            .background(AppColors.background)
            .navigationTitle("Entries")
            .navigationBarTitleDisplayMode(.large)
            .onTapGesture {
                // Dismiss keyboard when tapping outside input area
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                isInputFocused = false
            }
        }
    }
}

#Preview {
    EntriesView()
        .environmentObject(NotesStore())
}
