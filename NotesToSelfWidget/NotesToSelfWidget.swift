//
//  NotesToSelfWidget.swift
//  NotesToSelfWidget
//
//  Created by Daniel Nacamuli on 6/14/25.
//

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Widget Note Model
// Note: This is a widget-specific Note struct that matches the main app's structure
struct WidgetNote: Identifiable, Codable, Equatable {
    let id: UUID
    let text: String
    let date: Date
    let lastModified: Date
    
    init(id: UUID = UUID(), text: String, date: Date = Date(), lastModified: Date = Date()) {
        self.id = id
        self.text = text
        self.date = date
        self.lastModified = lastModified
    }
    
    // Custom coding keys to handle backward compatibility
    enum CodingKeys: String, CodingKey {
        case id, text, date, lastModified
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        text = try container.decode(String.self, forKey: .text)
        date = try container.decode(Date.self, forKey: .date)
        
        // Handle backward compatibility - if lastModified doesn't exist, use the date
        if let lastModified = try? container.decode(Date.self, forKey: .lastModified) {
            self.lastModified = lastModified
        } else {
            self.lastModified = date
        }
    }
}

// MARK: - Main App Note Model (for decoding)
// This matches the main app's Note struct exactly for decoding compatibility
struct MainAppNote: Identifiable, Codable, Equatable {
    let id: UUID
    let text: String
    let date: Date
    let lastModified: Date
    
    init(id: UUID = UUID(), text: String, date: Date = Date(), lastModified: Date = Date()) {
        self.id = id
        self.text = text
        self.date = date
        self.lastModified = lastModified
    }
    
    // Custom coding keys to handle backward compatibility
    enum CodingKeys: String, CodingKey {
        case id, text, date, lastModified
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        text = try container.decode(String.self, forKey: .text)
        date = try container.decode(Date.self, forKey: .date)
        
        // Handle backward compatibility - if lastModified doesn't exist, use the date
        if let lastModified = try? container.decode(Date.self, forKey: .lastModified) {
            self.lastModified = lastModified
        } else {
            self.lastModified = date
        }
    }
}

// MARK: - Shared Model
struct NotesData: Codable {
    var notes: [WidgetNote]
    var currentIndex: Int
}

let appGroupID = "group.co.uk.cursive.NotesToSelf"
let notesKey = "notes"
let indexKey = "currentIndex"

// MARK: - App Intent
struct NextNoteIntent: AppIntent {
    static var title: LocalizedStringResource = "Next Note"
    static var description = IntentDescription("Show the next note in the widget.")
    
    func perform() async throws -> some IntentResult {
        print("🔍 Widget: NextNoteIntent triggered")
        
        guard let ud = UserDefaults(suiteName: appGroupID) else { 
            print("❌ Widget: Failed to access UserDefaults in NextNoteIntent")
            return .result() 
        }
        
        let notes: [WidgetNote]
        if let data = ud.data(forKey: notesKey) {
            print("📊 Widget: Found data in NextNoteIntent, size: \(data.count) bytes")
            
            // Try to decode as WidgetNote first
            if let decoded = try? JSONDecoder().decode([WidgetNote].self, from: data) {
                notes = decoded
                print("✅ Widget: NextNoteIntent decoded \(decoded.count) WidgetNote objects")
            } else {
                print("⚠️ Widget: NextNoteIntent failed to decode as WidgetNote, trying Note...")
                
                // Try to decode as MainAppNote (from main app) and convert
                if let mainAppNotes = try? JSONDecoder().decode([MainAppNote].self, from: data) {
                    print("✅ Widget: NextNoteIntent decoded \(mainAppNotes.count) MainAppNote objects from main app")
                    // Convert MainAppNote to WidgetNote
                    notes = mainAppNotes.map { note in
                        WidgetNote(
                            id: note.id,
                            text: note.text,
                            date: note.date,
                            lastModified: note.lastModified
                        )
                    }
                    print("✅ Widget: NextNoteIntent converted to \(notes.count) WidgetNote objects")
                } else {
                    print("❌ Widget: NextNoteIntent failed to decode as MainAppNote either")
                    notes = []
                }
            }
        } else {
            print("❌ Widget: NextNoteIntent no data found for key: \(notesKey)")
            notes = []
        }
        
        guard !notes.isEmpty else { 
            print("❌ Widget: NextNoteIntent no notes available")
            return .result() 
        }
        
        var idx = ud.integer(forKey: indexKey)
        print("📊 Widget: NextNoteIntent current index: \(idx), notes count: \(notes.count)")
        
        idx = (idx + 1) % notes.count
        ud.set(idx, forKey: indexKey)
        print("✅ Widget: NextNoteIntent updated index to: \(idx)")
        
        WidgetCenter.shared.reloadAllTimelines()
        print("✅ Widget: NextNoteIntent reloaded widget timelines")
        
        return .result()
    }
}

// MARK: - Timeline Provider
struct NotesProvider: TimelineProvider {
    func placeholder(in context: Context) -> NotesEntry {
        NotesEntry(date: Date(), note: WidgetNote(id: UUID(), text: "Sample note", date: Date(), lastModified: Date()))
    }
    func getSnapshot(in context: Context, completion: @escaping (NotesEntry) -> Void) {
        let entry = loadEntry()
        completion(entry)
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<NotesEntry>) -> Void) {
        let entry = loadEntry()
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
    private func loadEntry() -> NotesEntry {
        print("🔍 Widget: Starting loadEntry()")
        
        guard let ud = UserDefaults(suiteName: appGroupID) else {
            print("❌ Widget: Failed to access UserDefaults with appGroupID: \(appGroupID)")
            return NotesEntry(date: Date(), note: WidgetNote(id: UUID(), text: "❌ No UserDefaults access", date: Date(), lastModified: Date()))
        }
        
        print("✅ Widget: UserDefaults accessed successfully")
        
        let notes: [WidgetNote]
        if let data = ud.data(forKey: notesKey) {
            print("📊 Widget: Found data, size: \(data.count) bytes")
            
            // Try to decode as WidgetNote first
            if let decoded = try? JSONDecoder().decode([WidgetNote].self, from: data) {
                notes = decoded
                print("✅ Widget: Successfully decoded \(decoded.count) WidgetNote objects")
            } else {
                print("⚠️ Widget: Failed to decode as WidgetNote, trying Note...")
                
                // Try to decode as MainAppNote (from main app) and convert
                if let mainAppNotes = try? JSONDecoder().decode([MainAppNote].self, from: data) {
                    print("✅ Widget: Successfully decoded \(mainAppNotes.count) MainAppNote objects from main app")
                    // Convert MainAppNote to WidgetNote
                    notes = mainAppNotes.map { note in
                        WidgetNote(
                            id: note.id,
                            text: note.text,
                            date: note.date,
                            lastModified: note.lastModified
                        )
                    }
                    print("✅ Widget: Converted to \(notes.count) WidgetNote objects")
                } else {
                    print("❌ Widget: Failed to decode as MainAppNote either")
                    notes = []
                }
            }
        } else {
            print("❌ Widget: No data found for key: \(notesKey)")
            notes = []
        }
        
        let idx = ud.integer(forKey: indexKey)
        print("📊 Widget: Current index: \(idx), Notes count: \(notes.count)")
        
        let note = (!notes.isEmpty && idx < notes.count) ? notes[idx] : WidgetNote(id: UUID(), text: "No notes available", date: Date(), lastModified: Date())
        print("📝 Widget: Selected note text: '\(note.text)'")
        
        return NotesEntry(date: Date(), note: note)
    }
}

struct NotesEntry: TimelineEntry {
    let date: Date
    let note: WidgetNote
}

// MARK: - Widget
struct NotesToSelfWidgetEntryView: View {
    var entry: NotesEntry
    @Environment(\.widgetFamily) var widgetFamily
    
    var body: some View {
        ZStack {
            // Text content
            Text(entry.note.text)
                .foregroundColor(AppColors.widgetText)
                .font(widgetFamily == .systemSmall ? AppTypography.widgetSmallFont : AppTypography.widgetLargeFont)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .padding(AppPadding.widgetTextPadding)
                .transition(.identity)
                .id(entry.note.id)
            
            // Button aligned to bottom-right corner
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    ZStack {
                        Button(intent: NextNoteIntent()) {
                            Circle()
                                .fill(AppColors.widgetButtonInvisible)
                                .frame(width: AppDimensions.widgetButtonInvisibleSize, height: AppDimensions.widgetButtonInvisibleSize)
                        }
                        .opacity(0.01)
                        
                        // Visible button with arrow
                        ZStack {
                            Circle()
                                .fill(Color.clear)
                                .frame(width: AppDimensions.widgetButtonVisibleSize, height: AppDimensions.widgetButtonVisibleSize)
                                .overlay(
                                    Circle()
                                        .stroke(Color.clear, lineWidth: 2)
                                )
                                .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                            
                            Image(systemName: "forward.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .offset(x: 40, y: 45)
                }
            }
        }
        .containerBackground(AppColors.widgetBackground, for: .widget)
    }
}

struct NotesToSelfWidgetEntryView_Previews: PreviewProvider {
    static var previews: some View {
        NotesToSelfWidgetEntryView(entry: NotesEntry(date: .now, note: WidgetNote(id: UUID(), text: "Preview note", date: .now, lastModified: .now)))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}

@main
struct NotesToSelfWidget: Widget {
    let kind: String = "NotesToSelfWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NotesProvider()) { entry in
            NotesToSelfWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Notes to Self")
        .description("View your saved notes and cycle through them.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
