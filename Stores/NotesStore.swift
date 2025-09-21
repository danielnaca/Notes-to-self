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
    @Published var editingNoteId: UUID? = nil
    
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
        editingNoteId = nil
    }
    
    func updateNote() {
        let trimmed = newNote.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let editingId = editingNoteId else { return }
        
        if let index = notes.firstIndex(where: { $0.id == editingId }) {
            let originalNote = notes[index]
            let updatedNote = Note(
                id: originalNote.id,
                text: trimmed,
                date: originalNote.date,
                lastModified: Date()
            )
            notes[index] = updatedNote
        }
        
        newNote = ""
        editingNoteId = nil
    }
    
    func startEditing(note: Note) {
        newNote = note.text
        editingNoteId = note.id
    }
    
    func cancelEditing() {
        newNote = ""
        editingNoteId = nil
    }
    
    var isEditing: Bool {
        editingNoteId != nil
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
        guard let ud = UserDefaults(suiteName: appGroupID) else { 
            print("Failed to access UserDefaults")
            return 
        }
        
        // Temporary debugging
        print("=== DEBUGGING STORAGE ===")
        let allKeys = ud.dictionaryRepresentation().keys
        print("All keys: \(Array(allKeys))")
        
        if let data = ud.data(forKey: notesKey) {
            print("Data size: \(data.count) bytes")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw JSON: \(jsonString)")
            }
            
            do {
                let decoded = try JSONDecoder().decode([Note].self, from: data)
                print("Decoded \(decoded.count) notes")
                notes = decoded
            } catch {
                print("Decode error: \(error)")
            }
        } else {
            print("No data found for key: \(notesKey)")
        }
        
        currentIndex = ud.integer(forKey: indexKey)
        print("Current index: \(currentIndex)")
        print("=== END DEBUGGING ===")
    }
} 