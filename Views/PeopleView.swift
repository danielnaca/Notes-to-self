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
    @State private var showingNewPerson = false
    
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
                        NavigationLink(destination: PeopleEditView(note: note).environmentObject(store)) {
                            PeopleRowView(note: note)
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
                    NavigationLink(destination: PeopleEditView(note: Note(text: "")).environmentObject(store), isActive: $showingNewPerson) {
                        Button(action: { showingNewPerson = true }) {
                            Image(systemName: "plus")
                                .foregroundColor(AppColors.accent)
                        }
                    }
                }
            }
        }
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
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .foregroundColor(AppColors.noteText)
                .lineLimit(1)
            
            Text(DateFormatter.peopleFormatter.string(from: note.date))
                .font(.caption)
                .foregroundColor(AppColors.secondaryText)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

#Preview {
    PeopleView()
        .environmentObject(NotesStore())
}

