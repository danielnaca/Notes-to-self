import Foundation
import SwiftUI
import UserNotifications
import CloudKit
import WidgetKit

// 📗 Reminders Data Store: Manages reminder data and operations
class RemindersStore: ObservableObject {
    @Published var reminders: [ReminderEntry] = [] {
        didSet { saveReminders() }
    }
    @Published var newReminder: String = ""
    @Published var currentIndex: Int = 0 { didSet { save() } }
    @Published var showNotificationAlert = false
    @Published var editingReminderId: UUID? = nil
    @Published var showImportExportAlert = false
    @Published var importExportMessage = ""
    
    private let appGroupID = "group.co.uk.cursive.NotesToSelf"
    private let remindersKey = "reminders"
    private let indexKey = "currentReminderIndex"
    private let cloudKit = CloudKitManager.shared
    private var isSyncing = false
    
    init() {
        loadFromCloudKit()
    }
    
    func addReminder() {
        let trimmed = newReminder.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        reminders.insert(ReminderEntry(text: trimmed), at: 0)
        newReminder = ""
        editingReminderId = nil
    }
    
    func updateReminder() {
        let trimmed = newReminder.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let editingId = editingReminderId else { return }
        
        if let index = reminders.firstIndex(where: { $0.id == editingId }) {
            let originalReminder = reminders[index]
            let updatedReminder = ReminderEntry(
                id: originalReminder.id,
                text: trimmed,
                date: originalReminder.date,
                lastModified: Date()
            )
            reminders[index] = updatedReminder
        }
        
        newReminder = ""
        editingReminderId = nil
    }
    
    func startEditing(reminder: ReminderEntry) {
        newReminder = reminder.text
        editingReminderId = reminder.id
    }
    
    func cancelEditing() {
        newReminder = ""
        editingReminderId = nil
    }
    
    var isEditing: Bool {
        editingReminderId != nil
    }
    
    func delete(at offsets: IndexSet) {
        reminders.remove(atOffsets: offsets)
        if currentIndex >= reminders.count { currentIndex = 0 }
    }
    
    func deleteReversed(at offsets: IndexSet) {
        // Convert reversed indices to original array indices
        let reversedIndices = offsets.map { reminders.count - 1 - $0 }
        let originalIndexSet = IndexSet(reversedIndices)
        reminders.remove(atOffsets: originalIndexSet)
        if currentIndex >= reminders.count { currentIndex = 0 }
    }
    
    func refreshNotificationQueue() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                if settings.authorizationStatus == .notDetermined {
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                        DispatchQueue.main.async {
                            self.showNotificationAlert = !granted
                        }
                        if granted { self.scheduleNotifications() }
                    }
                } else if settings.authorizationStatus == .authorized {
                    self.scheduleNotifications()
                } else {
                    DispatchQueue.main.async {
                        self.showNotificationAlert = true
                    }
                }
            }
        }
    }
    
    private func scheduleNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        guard !reminders.isEmpty else { return }
        let count = 10 // 10 notifications, 3 days apart = 30 days
        let calendar = Calendar.current
        let now = Date()
        for i in 0..<count {
            let content = UNMutableNotificationContent()
            guard let randomReminder = reminders.randomElement() else { continue }
            content.title = "Notes to Self"
            content.body = randomReminder.text
            content.sound = .default
            if let fireDate = calendar.date(byAdding: .day, value: i * 3, to: now) {
                let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: fireDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
                let request = UNNotificationRequest(identifier: "reminder_\(i)", content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        print("Notification scheduling error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    // MARK: - CloudKit Sync Methods
    
    private func loadFromCloudKit() {
        Task {
            do {
                guard await cloudKit.isCloudKitAvailable() else {
                    print("CloudKit not available, loading reminders from UserDefaults fallback")
                    await MainActor.run {
                        loadFromUserDefaults()
                    }
                    return
                }
                
                let fetchedReminders = try await cloudKit.fetchReminders()
                
                await MainActor.run {
                    isSyncing = true
                    self.reminders = fetchedReminders
                    isSyncing = false
                    print("Loaded \(fetchedReminders.count) reminders from CloudKit")
                }
            } catch {
                print("Error loading reminders from CloudKit: \(error)")
                await MainActor.run {
                    loadFromUserDefaults()
                }
            }
        }
    }
    
    private func saveReminders() {
        guard !isSyncing else { return }
        
        // Always save to UserDefaults for widget access
        saveRemindersToUserDefaults()
        
        Task {
            do {
                guard await cloudKit.isCloudKitAvailable() else {
                    print("CloudKit not available, UserDefaults already saved")
                    return
                }
                
                try await cloudKit.saveReminders(reminders)
                print("Saved \(reminders.count) reminders to CloudKit")
            } catch {
                print("Error saving reminders to CloudKit: \(error)")
            }
        }
    }
    
    private func save() {
        // For currentIndex - still use UserDefaults for simplicity
        guard let ud = UserDefaults(suiteName: appGroupID) else { return }
        ud.set(currentIndex, forKey: indexKey)
    }
    
    // MARK: - UserDefaults Fallback
    
    private func loadFromUserDefaults() {
        guard let ud = UserDefaults(suiteName: appGroupID) else { return }
        
        if let data = ud.data(forKey: remindersKey),
           let decoded = try? JSONDecoder().decode([ReminderEntry].self, from: data) {
            reminders = decoded
        }
        
        currentIndex = ud.integer(forKey: indexKey)
        print("Loaded from UserDefaults: \(reminders.count) reminders")
    }
    
    private func saveRemindersToUserDefaults() {
        guard let ud = UserDefaults(suiteName: appGroupID) else { return }
        if let data = try? JSONEncoder().encode(reminders) {
            ud.set(data, forKey: remindersKey)
            
            // Tell the widget to reload
            WidgetCenter.shared.reloadAllTimelines()
            print("📱 Widget reloaded - \(reminders.count) reminders saved")
        }
    }
}

