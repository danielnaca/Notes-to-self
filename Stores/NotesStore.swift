import Foundation
import SwiftUI
import UserNotifications

// 📗 Notes Data Store: Manages all note data and operations
class NotesStore: ObservableObject {
    @Published var notes: [Note] = [] {
        didSet { save() }
    }
    @Published var newNote: String = ""
    @Published var currentIndex: Int = 0 { didSet { save() } }
    @Published var showNotificationAlert = false
    
    private let appGroupID = "group.co.uk.cursive.NotesToSelf"
    private let notesKey = "notes"
    private let indexKey = "currentIndex"
    
    init() {
        load()
    }
    
    func addNote() {
        let trimmed = newNote.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        notes.insert(Note(text: trimmed), at: 0)
        newNote = ""
    }
    
    func delete(at offsets: IndexSet) {
        notes.remove(atOffsets: offsets)
        if currentIndex >= notes.count { currentIndex = 0 }
    }
    
    func deleteReversed(at offsets: IndexSet) {
        // Convert reversed indices to original array indices
        let reversedIndices = offsets.map { notes.count - 1 - $0 }
        let originalIndexSet = IndexSet(reversedIndices)
        notes.remove(atOffsets: originalIndexSet)
        if currentIndex >= notes.count { currentIndex = 0 }
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
        guard !notes.isEmpty else { return }
        let count = 10 // 10 notifications, 3 days apart = 30 days
        let calendar = Calendar.current
        let now = Date()
        for i in 0..<count {
            let content = UNMutableNotificationContent()
            guard let randomNote = notes.randomElement() else { continue }
            content.title = "Notes to Self"
            content.body = randomNote.text
            content.sound = .default
            if let fireDate = calendar.date(byAdding: .day, value: i * 3, to: now) {
                let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: fireDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
                let request = UNNotificationRequest(identifier: "note_\(i)", content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        print("Notification scheduling error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    private func save() {
        guard let ud = UserDefaults(suiteName: appGroupID) else { return }
        if let data = try? JSONEncoder().encode(notes) {
            ud.set(data, forKey: notesKey)
        }
        ud.set(currentIndex, forKey: indexKey)
    }
    
    private func load() {
        guard let ud = UserDefaults(suiteName: appGroupID) else { return }
        if let data = ud.data(forKey: notesKey), let decoded = try? JSONDecoder().decode([Note].self, from: data) {
            notes = decoded
        }
        currentIndex = ud.integer(forKey: indexKey)
    }
} 