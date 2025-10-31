//
//  CBTCalendarView.swift
//  Notes to self
//
//  Created by AI Assistant on 10/31/25.
//

import SwiftUI
import UIKit

// 📗 CBT Calendar View: Shows CBT entries in a calendar format
struct CBTCalendarView: View {
    @EnvironmentObject var store: CBTStore
    @State private var selectedDate: Date?
    @State private var showingDayEntries = false
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                CalendarViewRepresentable(
                    entries: store.entries,
                    onDateTap: handleDateTap
                )
                .background(Color.white)
            }
            .navigationDestination(for: CBTEntry.self) { entry in
                CBTEntryView(entry: entry)
                    .environmentObject(store)
            }
            .sheet(isPresented: $showingDayEntries) {
                if let date = selectedDate {
                    DayEntriesSheet(
                        date: date,
                        entries: entriesForDate(date),
                        onSelectEntry: { entry in
                            showingDayEntries = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                navigationPath.append(entry)
                            }
                        }
                    )
                }
            }
        }
    }
    
    private func handleDateTap(date: Date) {
        let entries = entriesForDate(date)
        
        if entries.count == 1 {
            navigationPath.append(entries[0])
        } else if entries.count > 1 {
            selectedDate = date
            showingDayEntries = true
        }
    }
    
    private func entriesForDate(_ date: Date) -> [CBTEntry] {
        let calendar = Calendar.current
        return store.entries.filter { entry in
            calendar.isDate(entry.date, inSameDayAs: date)
        }
    }
}

// 📗 Calendar View Representable: Wraps UICalendarView for SwiftUI
struct CalendarViewRepresentable: UIViewRepresentable {
    let entries: [CBTEntry]
    let onDateTap: (Date) -> Void
    
    func makeUIView(context: Context) -> UICalendarView {
        let calendarView = UICalendarView()
        calendarView.backgroundColor = .white
        calendarView.calendar = Calendar.current
        calendarView.fontDesign = .rounded
        
        // Store reference in coordinator first
        context.coordinator.calendarView = calendarView
        
        // Set delegate
        calendarView.delegate = context.coordinator
        
        // Configure date selection
        let dateSelection = UICalendarSelectionSingleDate(delegate: context.coordinator)
        calendarView.selectionBehavior = dateSelection
        
        // Set available date range
        setAvailableDateRange(for: calendarView)
        
        return calendarView
    }
    
    private func setAvailableDateRange(for calendarView: UICalendarView) {
        guard !entries.isEmpty else { return }
        
        let calendar = Calendar.current
        
        // Get earliest entry date
        guard let earliestEntry = entries.min(by: { $0.date < $1.date }) else { return }
        
        // Start of the earliest entry's month
        let startComponents = calendar.dateComponents([.year, .month], from: earliestEntry.date)
        guard let startDate = calendar.date(from: startComponents) else { return }
        
        // End of current month
        let now = Date()
        let endComponents = calendar.dateComponents([.year, .month], from: now)
        guard let endOfMonth = calendar.date(from: endComponents),
              let lastDayOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: endOfMonth) else { return }
        
        // Set the range
        calendarView.availableDateRange = DateInterval(start: startDate, end: lastDayOfMonth)
    }
    
    func updateUIView(_ uiView: UICalendarView, context: Context) {
        // Update coordinator data
        context.coordinator.entries = entries
        context.coordinator.onDateTap = onDateTap
        context.coordinator.calendarView = uiView
        
        // Update available date range
        setAvailableDateRange(for: uiView)
        
        // Reload all decorations for dates that have entries
        let calendar = Calendar.current
        let dateSet = Set(entries.map { calendar.startOfDay(for: $0.date) })
        let dateComponents = dateSet.map { calendar.dateComponents([.year, .month, .day], from: $0) }
        
        if !dateComponents.isEmpty {
            uiView.reloadDecorations(forDateComponents: dateComponents, animated: false)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(entries: entries, onDateTap: onDateTap)
    }
    
    class Coordinator: NSObject, UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate {
        var entries: [CBTEntry]
        var onDateTap: (Date) -> Void
        weak var calendarView: UICalendarView?
        
        init(entries: [CBTEntry], onDateTap: @escaping (Date) -> Void) {
            self.entries = entries
            self.onDateTap = onDateTap
        }
        
        // MARK: - UICalendarViewDelegate
        
        func calendarView(_ calendarView: UICalendarView, decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
            guard let date = Calendar.current.date(from: dateComponents) else { 
                return nil 
            }
            
            // Filter entries for this specific day
            let calendar = Calendar.current
            let entriesForDay = entries.filter { entry in
                calendar.isDate(entry.date, inSameDayAs: date)
            }
            
            guard !entriesForDay.isEmpty else { 
                return nil 
            }
            
            // Get unique emojis for this day
            let uniqueEmojis = getUniqueEmojis(for: entriesForDay)
            
            // If no emojis, show a dot
            if uniqueEmojis.isEmpty {
                return .default(color: .systemBlue, size: .large)
            }
            
            // Show emojis
            let emojiString = uniqueEmojis.prefix(3).joined()
            return .customView {
                let label = UILabel()
                label.text = emojiString
                label.font = .systemFont(ofSize: 14)
                label.textAlignment = .center
                label.numberOfLines = 1
                return label
            }
        }
        
        private func getUniqueEmojis(for entries: [CBTEntry]) -> [String] {
            var seenEmojis = Set<String>()
            var uniqueEmojis: [String] = []
            
            for entry in entries {
                for distortionId in entry.distortionIds {
                    if let distortion = CognitiveDistortion.allDistortions.first(where: { $0.id == distortionId }) {
                        if !seenEmojis.contains(distortion.emoji) {
                            seenEmojis.insert(distortion.emoji)
                            uniqueEmojis.append(distortion.emoji)
                        }
                    }
                }
            }
            
            return uniqueEmojis
        }
        
        // MARK: - UICalendarSelectionSingleDateDelegate
        
        func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
            guard let dateComponents = dateComponents,
                  let date = Calendar.current.date(from: dateComponents) else { return }
            
            onDateTap(date)
            
            // Deselect immediately so it doesn't stay highlighted
            DispatchQueue.main.async {
                selection.setSelected(nil, animated: true)
            }
        }
    }
}

// 📗 Day Entries Sheet: Shows entries for a specific day
struct DayEntriesSheet: View {
    let date: Date
    let entries: [CBTEntry]
    let onSelectEntry: (CBTEntry) -> Void
    @Environment(\.dismiss) private var dismiss
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
    
    var body: some View {
        NavigationView {
            List(entries) { entry in
                Button(action: {
                    onSelectEntry(entry)
                }) {
                    CBTEntryRow(entry: entry)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .navigationTitle(dateString)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.accent)
                }
            }
        }
    }
}

#Preview {
    CBTCalendarView()
        .environmentObject(CBTStore())
}

