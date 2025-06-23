//
//  NotesToSelfWidget.swift
//  NotesToSelfWidget
//
//  Created by Daniel Nacamuli on 6/14/25.
//

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Shared Model
struct NotesData: Codable {
    var notes: [Note]
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
        guard let ud = UserDefaults(suiteName: appGroupID) else { return .result() }
        let notes: [Note]
        if let data = ud.data(forKey: notesKey), let decoded = try? JSONDecoder().decode([Note].self, from: data) {
            notes = decoded
        } else {
            notes = []
        }
        guard !notes.isEmpty else { return .result() }
        var idx = ud.integer(forKey: indexKey)
        idx = (idx + 1) % notes.count
        ud.set(idx, forKey: indexKey)
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

// MARK: - Timeline Provider
struct NotesProvider: TimelineProvider {
    func placeholder(in context: Context) -> NotesEntry {
        NotesEntry(date: Date(), note: Note(id: UUID(), text: "Sample note", date: Date()))
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
        guard let ud = UserDefaults(suiteName: appGroupID) else {
            return NotesEntry(date: Date(), note: Note(id: UUID(), text: "No notes", date: Date()))
        }
        let notes: [Note]
        if let data = ud.data(forKey: notesKey), let decoded = try? JSONDecoder().decode([Note].self, from: data) {
            notes = decoded
        } else {
            notes = []
        }
        let idx = ud.integer(forKey: indexKey)
        let note = (!notes.isEmpty && idx < notes.count) ? notes[idx] : Note(id: UUID(), text: "No notes", date: Date())
        return NotesEntry(date: Date(), note: note)
    }
}

struct NotesEntry: TimelineEntry {
    let date: Date
    let note: Note
}

// MARK: - Widget
struct NotesToSelfWidgetEntryView: View {
    var entry: NotesEntry
    @Environment(\.widgetFamily) var widgetFamily
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Text content
                Text(entry.note.text)
                    .foregroundColor(AppColors.widgetText)
                    .font(widgetFamily == .systemSmall ? AppTypography.widgetSmallFont : AppTypography.widgetLargeFont)
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(AppPadding.widgetTextPadding)
                
                // Button absolutely positioned at bottom-right corner
                ZStack {
                    Button(intent: NextNoteIntent()) {
                        Circle()
                            .fill(AppColors.widgetButtonInvisible)
                            .frame(width: AppDimensions.widgetButtonInvisibleSize, height: AppDimensions.widgetButtonInvisibleSize)
                    }
                    .opacity(0.01)
                    Circle()
                        .fill(AppColors.widgetButtonVisible)
                        .frame(width: AppDimensions.widgetButtonVisibleSize, height: AppDimensions.widgetButtonVisibleSize)
                }
                .position(x: geometry.size.width, y: geometry.size.height)
            }
        }
        .containerBackground(AppColors.widgetBackground, for: .widget)
    }
}

struct NotesToSelfWidgetEntryView_Previews: PreviewProvider {
    static var previews: some View {
        NotesToSelfWidgetEntryView(entry: NotesEntry(date: .now, note: Note(id: UUID(), text: "Preview note", date: .now)))
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
