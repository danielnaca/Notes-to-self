//
//  CBTListView.swift
//  Notes to self
//
//  Created by AI Assistant on 10/31/25.
//

import SwiftUI

// 📗 CBT List View: Shows all CBT entries with date and situation preview
struct CBTListView: View {
    @EnvironmentObject var store: CBTStore
    @State private var showingCalendar = false
    
    var body: some View {
        NavigationView {
            Group {
                if showingCalendar {
                    CBTCalendarView()
                        .environmentObject(store)
                } else {
                    VStack(spacing: 0) {
                        // Development: Generate mock data button (remove in production)
                        #if DEBUG
                        if store.entries.isEmpty {
                            Button("Generate Mock Data") {
                                store.generateMockEntries()
                            }
                            .padding()
                            .foregroundColor(.red)
                        }
                        #endif
                        
                        // New entry button
                        NavigationLink(destination: CBTEntryView(entry: CBTEntry()).environmentObject(store)) {
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
                        if store.entries.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "brain.head.profile")
                                    .font(.system(size: 64))
                                    .foregroundColor(AppColors.secondaryText)
                                Text("No CBT Entries Yet")
                                    .font(.title2)
                                    .foregroundColor(AppColors.secondaryText)
                                Text("Tap 'New' above to create your first thought record")
                                    .font(.body)
                                    .foregroundColor(AppColors.tertiaryText)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            List(store.entries) { entry in
                                ZStack {
                                    NavigationLink(destination: CBTEntryView(entry: entry).environmentObject(store)) {
                                        EmptyView()
                                    }
                                    .opacity(0)
                                    
                                    CBTEntryRow(entry: entry)
                                }
                            }
                            .listStyle(PlainListStyle())
                        }
                    }
                    .background(Color.white)
                }
            }
            .navigationTitle("CBT")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.white, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCalendar.toggle() }) {
                        Image(systemName: showingCalendar ? "list.bullet" : "calendar")
                            .foregroundColor(AppColors.accent)
                    }
                }
            }
        }
    }
}

// 📗 CBT Entry Row: Shows date and first line of situation
struct CBTEntryRow: View {
    let entry: CBTEntry
    
    private var situationPreview: String {
        let lines = entry.situation.components(separatedBy: .newlines)
        return lines.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Empty entry"
    }
    
    private var distortionEmojis: [String] {
        entry.distortionIds.compactMap { id in
            CognitiveDistortion.allDistortions.first(where: { $0.id == id })?.emoji
        }
    }
    
    private func naturalDateString(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if let daysAgo = calendar.dateComponents([.day], from: date, to: now).day,
                  daysAgo < 7 {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE" // Day name
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(naturalDateString(from: entry.date))
                    .font(.caption)
                    .foregroundColor(AppColors.secondaryText)
                
                Text(situationPreview)
                    .font(.body)
                    .foregroundColor(AppColors.noteText)
                    .lineLimit(1)
            }
            
            Spacer()
            
            if !distortionEmojis.isEmpty {
                HStack(spacing: 4) {
                    ForEach(distortionEmojis.prefix(3), id: \.self) { emoji in
                        Text(emoji)
                            .font(.body)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    CBTListView()
        .environmentObject(CBTStore())
}

