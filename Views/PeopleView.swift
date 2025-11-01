//
//  PeopleView.swift
//  Notes to self
//
//  Created by AI Assistant on 9/30/25.
//

import SwiftUI

// 📗 People View: List view of entries with edit functionality
struct PeopleView: View {
    @EnvironmentObject var store: PeopleStore
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // New entry button
                NavigationLink(destination: PeopleEditView(person: PersonEntry(text: "")).environmentObject(store)) {
                    HStack {
                        Text("New")
                            .font(.headline)
                            .foregroundColor(AppColors.accent)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(AppColors.tertiaryText)
                    }
                    .padding()
                    .background(Color.white)
                }
                .buttonStyle(PlainButtonStyle())
                
                // List of entries
                if store.people.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Image(systemName: "person.2")
                            .font(.system(size: 64))
                            .foregroundColor(AppColors.secondaryText)
                        
                        Text("No People Yet")
                            .font(.title2)
                            .foregroundColor(AppColors.secondaryText)
                        
                        Text("Tap 'New' above to create your first entry")
                            .font(.body)
                            .foregroundColor(AppColors.tertiaryText)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(store.people) { person in
                        NavigationLink(destination: PeopleEditView(person: person).environmentObject(store)) {
                            PeopleRowView(person: person)
                        }
                    }
                    .listStyle(PlainListStyle())
                    .background(AppColors.listBackground)
                }
            }
            .background(AppColors.background)
            .navigationTitle("People")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// 📗 People Row View: Individual row showing entry title
struct PeopleRowView: View {
    let person: PersonEntry
    
    private var title: String {
        // Get first line of text as title
        let lines = person.text.components(separatedBy: .newlines)
        return lines.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? person.text
    }
    
    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundColor(AppColors.noteText)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
    }
}

#Preview {
    PeopleView()
        .environmentObject(PeopleStore())
}

