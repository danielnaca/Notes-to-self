import Foundation
import SwiftUI
import UserNotifications
import UniformTypeIdentifiers

// 📗 Notes Data Store: Manages all note data and operations
class NotesStore: ObservableObject {
    @Published var notes: [Note] = [] {
        didSet { save() }
    }
    @Published var people: [Note] = [] {
        didSet { savePeople() }
    }
    @Published var newNote: String = ""
    @Published var currentIndex: Int = 0 { didSet { save() } }
    @Published var showNotificationAlert = false
    @Published var editingNoteId: UUID? = nil
    @Published var showImportExportAlert = false
    @Published var importExportMessage = ""
    
    private let appGroupID = "group.co.uk.cursive.NotesToSelf"
    private let notesKey = "notes"
    private let peopleKey = "people"
    private let indexKey = "currentIndex"
    
    init() {
        load()
        loadPeople()
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
    
    private func savePeople() {
        guard let ud = UserDefaults(suiteName: appGroupID) else { return }
        if let data = try? JSONEncoder().encode(people) {
            ud.set(data, forKey: peopleKey)
        }
    }
    
    private func loadPeople() {
        guard let ud = UserDefaults(suiteName: appGroupID) else { return }
        if let data = ud.data(forKey: peopleKey),
           let decoded = try? JSONDecoder().decode([Note].self, from: data) {
            people = decoded
        }
    }
    
    // MARK: - Import/Export Functions
    
    func exportNotes() -> URL? {
        let exportData = NotesExportData(
            notes: notes,
            exportDate: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
            totalNotes: notes.count
        )
        
        guard let data = try? JSONEncoder().encode(exportData) else {
            importExportMessage = "Failed to export notes"
            showImportExportAlert = true
            return nil
        }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "notes_to_self_export_\(DateFormatter.exportDateFormatter.string(from: Date())).json"
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            importExportMessage = "Failed to save export file: \(error.localizedDescription)"
            showImportExportAlert = true
            return nil
        }
    }
    
    func importNotes(from data: Data) {
        guard let importData = try? JSONDecoder().decode(NotesExportData.self, from: data) else {
            importExportMessage = "Invalid file format. Please select a valid Notes to Self export file."
            showImportExportAlert = true
            return
        }
        
        let importedNotes = importData.notes
        var newNotesCount = 0
        var updatedNotesCount = 0
        
        // Create a dictionary of existing notes by UUID for fast lookup
        var existingNotesMap: [UUID: Note] = [:]
        for note in notes {
            existingNotesMap[note.id] = note
        }
        
        var mergedNotes: [Note] = []
        
        // Add all existing notes first
        mergedNotes.append(contentsOf: notes)
        
        // Process imported notes
        for importedNote in importedNotes {
            if let existingNote = existingNotesMap[importedNote.id] {
                // UUID conflict - keep the more recently modified note
                if importedNote.lastModified > existingNote.lastModified {
                    // Replace existing note with imported one
                    if let index = mergedNotes.firstIndex(where: { $0.id == importedNote.id }) {
                        mergedNotes[index] = importedNote
                        updatedNotesCount += 1
                    }
                }
                // If existing note is newer, keep it (do nothing)
            } else {
                // New note - add it
                mergedNotes.append(importedNote)
                newNotesCount += 1
            }
        }
        
        // Update the notes array
        notes = mergedNotes
        
        // Show success message
        var message = "Import completed successfully!\n"
        message += "• Added \(newNotesCount) new notes\n"
        if updatedNotesCount > 0 {
            message += "• Updated \(updatedNotesCount) existing notes\n"
        }
        message += "• Total notes: \(notes.count)"
        
        importExportMessage = message
        showImportExportAlert = true
    }
}

// MARK: - Export Data Structure
struct NotesExportData: Codable {
    let notes: [Note]
    let exportDate: Date
    let appVersion: String
    let totalNotes: Int
}

// MARK: - Date Formatter Extension
extension DateFormatter {
    static let exportDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter
    }()
} 