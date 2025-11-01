//
//  NotesToSelfWidget.swift
//  NotesToSelfWidget
//
//  Created by Daniel Nacamuli on 6/14/25.
//

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Widget Reminder Model
// Note: This is a widget-specific Reminder struct that matches the main app's structure
struct WidgetReminder: Identifiable, Codable, Equatable {
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

// MARK: - Main App Reminder Model (for decoding)
// This matches the main app's ReminderEntry struct exactly for decoding compatibility
struct MainAppReminder: Identifiable, Codable, Equatable {
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
struct RemindersData: Codable {
    var reminders: [WidgetReminder]
    var currentIndex: Int
}

let appGroupID = "group.co.uk.cursive.NotesToSelf"
let remindersKey = "reminders"
let indexKey = "currentReminderIndex"

// MARK: - App Intent
struct NextReminderIntent: AppIntent {
    static var title: LocalizedStringResource = "Next Reminder"
    static var description = IntentDescription("Show the next reminder in the widget.")
    
    func perform() async throws -> some IntentResult {
        print("🔍 Widget: NextReminderIntent triggered")
        
        guard let ud = UserDefaults(suiteName: appGroupID) else { 
            print("❌ Widget: Failed to access UserDefaults in NextReminderIntent")
            return .result() 
        }
        
        let reminders: [WidgetReminder]
        if let data = ud.data(forKey: remindersKey) {
            print("📊 Widget: Found data in NextReminderIntent, size: \(data.count) bytes")
            
            // Try to decode as WidgetReminder first
            if let decoded = try? JSONDecoder().decode([WidgetReminder].self, from: data) {
                reminders = decoded
                print("✅ Widget: NextReminderIntent decoded \(decoded.count) WidgetReminder objects")
            } else {
                print("⚠️ Widget: NextReminderIntent failed to decode as WidgetReminder, trying MainAppReminder...")
                
                // Try to decode as MainAppReminder (from main app) and convert
                if let mainAppReminders = try? JSONDecoder().decode([MainAppReminder].self, from: data) {
                    print("✅ Widget: NextReminderIntent decoded \(mainAppReminders.count) MainAppReminder objects from main app")
                    // Convert MainAppReminder to WidgetReminder
                    reminders = mainAppReminders.map { reminder in
                        WidgetReminder(
                            id: reminder.id,
                            text: reminder.text,
                            date: reminder.date,
                            lastModified: reminder.lastModified
                        )
                    }
                    print("✅ Widget: NextReminderIntent converted to \(reminders.count) WidgetReminder objects")
                } else {
                    print("❌ Widget: NextReminderIntent failed to decode as MainAppReminder either")
                    reminders = []
                }
            }
        } else {
            print("❌ Widget: NextReminderIntent no data found for key: \(remindersKey)")
            reminders = []
        }
        
        guard !reminders.isEmpty else { 
            print("❌ Widget: NextReminderIntent no reminders available")
            return .result() 
        }
        
        var idx = ud.integer(forKey: indexKey)
        print("📊 Widget: NextReminderIntent current index: \(idx), reminders count: \(reminders.count)")
        
        idx = (idx + 1) % reminders.count
        ud.set(idx, forKey: indexKey)
        print("✅ Widget: NextReminderIntent updated index to: \(idx)")
        
        WidgetCenter.shared.reloadAllTimelines()
        print("✅ Widget: NextReminderIntent reloaded widget timelines")
        
        return .result()
    }
}

// MARK: - Timeline Provider
struct RemindersProvider: TimelineProvider {
    func placeholder(in context: Context) -> RemindersEntry {
        RemindersEntry(date: Date(), reminder: WidgetReminder(id: UUID(), text: "Sample reminder", date: Date(), lastModified: Date()))
    }
    func getSnapshot(in context: Context, completion: @escaping (RemindersEntry) -> Void) {
        let entry = loadEntry()
        completion(entry)
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<RemindersEntry>) -> Void) {
        let entry = loadEntry()
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
    private func loadEntry() -> RemindersEntry {
        print("🔍 Widget: Starting loadEntry()")
        
        guard let ud = UserDefaults(suiteName: appGroupID) else {
            print("❌ Widget: Failed to access UserDefaults with appGroupID: \(appGroupID)")
            return RemindersEntry(date: Date(), reminder: WidgetReminder(id: UUID(), text: "❌ No UserDefaults access", date: Date(), lastModified: Date()))
        }
        
        print("✅ Widget: UserDefaults accessed successfully")
        
        let reminders: [WidgetReminder]
        if let data = ud.data(forKey: remindersKey) {
            print("📊 Widget: Found data, size: \(data.count) bytes")
            
            // Try to decode as WidgetReminder first
            if let decoded = try? JSONDecoder().decode([WidgetReminder].self, from: data) {
                reminders = decoded
                print("✅ Widget: Successfully decoded \(decoded.count) WidgetReminder objects")
            } else {
                print("⚠️ Widget: Failed to decode as WidgetReminder, trying MainAppReminder...")
                
                // Try to decode as MainAppReminder (from main app) and convert
                if let mainAppReminders = try? JSONDecoder().decode([MainAppReminder].self, from: data) {
                    print("✅ Widget: Successfully decoded \(mainAppReminders.count) MainAppReminder objects from main app")
                    // Convert MainAppReminder to WidgetReminder
                    reminders = mainAppReminders.map { reminder in
                        WidgetReminder(
                            id: reminder.id,
                            text: reminder.text,
                            date: reminder.date,
                            lastModified: reminder.lastModified
                        )
                    }
                    print("✅ Widget: Converted to \(reminders.count) WidgetReminder objects")
                } else {
                    print("❌ Widget: Failed to decode as MainAppReminder either")
                    reminders = []
                }
            }
        } else {
            print("❌ Widget: No data found for key: \(remindersKey)")
            reminders = []
        }
        
        let idx = ud.integer(forKey: indexKey)
        print("📊 Widget: Current index: \(idx), Reminders count: \(reminders.count)")
        
        let reminder = (!reminders.isEmpty && idx < reminders.count) ? reminders[idx] : WidgetReminder(id: UUID(), text: "No reminders available", date: Date(), lastModified: Date())
        print("📝 Widget: Selected reminder text: '\(reminder.text)'")
        
        return RemindersEntry(date: Date(), reminder: reminder)
    }
}

struct RemindersEntry: TimelineEntry {
    let date: Date
    let reminder: WidgetReminder
}

// MARK: - Widget
struct NotesToSelfWidgetEntryView: View {
    var entry: RemindersEntry
    @Environment(\.widgetFamily) var widgetFamily
    
    var body: some View {
        ZStack {
            // Text content
            Text(entry.reminder.text)
                .foregroundColor(AppColors.widgetText)
                .font(widgetFamily == .systemSmall ? AppTypography.widgetSmallFont : AppTypography.widgetLargeFont)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .padding(AppPadding.widgetTextPadding)
                .transition(.identity)
                .id(entry.reminder.id)
            
            // Button aligned to bottom-right corner
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    ZStack {
                        Button(intent: NextReminderIntent()) {
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
        NotesToSelfWidgetEntryView(entry: RemindersEntry(date: .now, reminder: WidgetReminder(id: UUID(), text: "Preview reminder", date: .now, lastModified: .now)))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}

@main
struct NotesToSelfWidget: Widget {
    let kind: String = "NotesToSelfWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RemindersProvider()) { entry in
            NotesToSelfWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Notes to Self")
        .description("View your saved reminders and cycle through them.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
