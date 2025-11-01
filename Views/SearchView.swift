//
//  SearchView.swift
//  Notes to self
//
//  Created by AI Assistant on 10/31/25.
//

import SwiftUI

// 📗 Search View: Global search across Reminders, People, and CBT
struct SearchView: View {
    @EnvironmentObject var remindersStore: RemindersStore
    @EnvironmentObject var peopleStore: PeopleStore
    @Binding var isActive: Bool
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
    @State private var keyboardHeight: CGFloat = 0
    
    var searchResults: [SearchResult] {
        guard !searchText.isEmpty else { return [] }
        
        var results: [SearchResult] = []
        
        // Search reminders
        let matchingReminders = remindersStore.reminders.filter { reminder in
            reminder.text.localizedCaseInsensitiveContains(searchText)
        }
        results.append(contentsOf: matchingReminders.map { SearchResult.reminder($0) })
        
        // Search people
        let matchingPeople = peopleStore.people.filter { person in
            person.text.localizedCaseInsensitiveContains(searchText)
        }
        results.append(contentsOf: matchingPeople.map { SearchResult.person($0) })
        
        return results
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Results area
                ScrollView {
                    if searchText.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 64))
                                .foregroundColor(AppColors.secondaryText)
                            Text("Search Reminders and People")
                                .font(.title2)
                                .foregroundColor(AppColors.secondaryText)
                            Text("Start typing to find your content")
                                .font(.body)
                                .foregroundColor(AppColors.tertiaryText)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if searchResults.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 64))
                                .foregroundColor(AppColors.secondaryText)
                            Text("No Results")
                                .font(.title2)
                                .foregroundColor(AppColors.secondaryText)
                            Text("No reminders or people match '\(searchText)'")
                                .font(.body)
                                .foregroundColor(AppColors.tertiaryText)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        LazyVStack(spacing: 0) {
                            ForEach(searchResults) { result in
                                NavigationLink(destination: destinationView(for: result)) {
                                    SearchResultRow(result: result, searchText: searchText)
                                        .padding(.horizontal)
                                        .padding(.vertical, 12)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                if result.id != searchResults.last?.id {
                                    Divider()
                                        .padding(.leading, 16)
                                }
                            }
                        }
                        .padding(.top, 8)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    isSearchFocused = false
                }
                
                // Input bar at bottom
                ZStack(alignment: .bottomTrailing) {
                    TextField("Search...", text: $searchText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .padding(.trailing, 40)
                        .background(Color(.systemGray6))
                        .cornerRadius(20)
                        .focused($isSearchFocused)
                        .lineLimit(1...5)
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(AppColors.secondaryText)
                                .font(.system(size: 20))
                        }
                        .padding(.trailing, 8)
                        .padding(.bottom, 6)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.white)
                .padding(.bottom, keyboardHeight)
            }
            .ignoresSafeArea(.keyboard)
            .background(Color.white)
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.white, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .task {
                setupKeyboardObservers()
            }
            .onChange(of: isActive) { _, active in
                if active {
                    // Focus when search tab becomes active
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        isSearchFocused = true
                    }
                }
            }
            .onAppear {
                // Initial focus if already on search tab
                if isActive {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        isSearchFocused = true
                    }
                }
            }
        }
    }
    
    // MARK: - Keyboard Handling
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
            guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            keyboardHeight = keyboardFrame.height - 80
        }
        
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
            keyboardHeight = 0
        }
    }
    
    @ViewBuilder
    private func destinationView(for result: SearchResult) -> some View {
        switch result {
        case .reminder(let reminder):
            ReminderDetailView(reminder: reminder)
                .environmentObject(remindersStore)
        case .person(let person):
            PeopleEditView(person: person)
                .environmentObject(peopleStore)
        }
    }
}

// 📗 Reminder Detail View: Shows a single reminder's content
struct ReminderDetailView: View {
    let reminder: ReminderEntry
    @EnvironmentObject var store: RemindersStore
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: reminder.date)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(formattedDate)
                    .font(.caption)
                    .foregroundColor(AppColors.secondaryText)
                
                Text(reminder.text)
                    .font(.body)
                    .foregroundColor(AppColors.noteText)
                    .textSelection(.enabled)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.white)
        .navigationTitle("Reminder")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// 📗 Search Result: Union type for reminders and people
enum SearchResult: Identifiable {
    case reminder(ReminderEntry)
    case person(PersonEntry)
    
    var id: UUID {
        switch self {
        case .reminder(let reminder):
            return reminder.id
        case .person(let person):
            return person.id
        }
    }
    
    var text: String {
        switch self {
        case .reminder(let reminder):
            return reminder.text
        case .person(let person):
            return person.text
        }
    }
    
    var date: Date {
        switch self {
        case .reminder(let reminder):
            return reminder.date
        case .person(let person):
            return person.date
        }
    }
    
    var type: String {
        switch self {
        case .reminder: return "Reminder"
        case .person: return "Person"
        }
    }
}

// 📗 Search Result Row: Displays a single search result
struct SearchResultRow: View {
    let result: SearchResult
    let searchText: String
    
    private var preview: String {
        let text = result.text
        let lines = text.components(separatedBy: CharacterSet.newlines)
        return lines.first?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) ?? "Empty"
    }
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(result.type)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(result.type == "Reminder" ? Color.blue : Color.purple)
                        .cornerRadius(4)
                    
                    Text(result.date, style: .date)
                        .font(.caption)
                        .foregroundColor(AppColors.secondaryText)
                }
                
                Text(preview)
                    .font(.body)
                    .foregroundColor(AppColors.noteText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(AppColors.tertiaryText)
        }
    }
}

#Preview {
    SearchView(isActive: .constant(true))
        .environmentObject(RemindersStore())
        .environmentObject(PeopleStore())
}

