//
//  CloudKitManager.swift
//  Notes to self
//
//  Created by AI Assistant on 10/31/25.
//

import Foundation
import CloudKit

// 📗 CloudKit Manager: Handles all CloudKit operations for syncing data
class CloudKitManager {
    static let shared = CloudKitManager()
    
    private let container: CKContainer
    private let privateDatabase: CKDatabase
    
    // Record type names
    private let reminderRecordType = "ReminderEntry"
    private let personRecordType = "PersonEntry"
    private let cbtEntryRecordType = "CBTEntry"
    private let todoRecordType = "TodoItem"
    
    private init() {
        container = CKContainer.default()
        privateDatabase = container.privateCloudDatabase
    }
    
    // MARK: - Reminder Operations
    
    func saveReminder(_ reminder: ReminderEntry) async throws {
        let record = reminderToRecord(reminder)
        try await privateDatabase.save(record)
    }
    
    func fetchReminders() async throws -> [ReminderEntry] {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: reminderRecordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        
        let results = try await privateDatabase.records(matching: query)
        
        var reminders: [ReminderEntry] = []
        for (_, result) in results.matchResults {
            switch result {
            case .success(let record):
                if let reminder = recordToReminder(record) {
                    reminders.append(reminder)
                }
            case .failure(let error):
                print("Error fetching reminder: \(error)")
            }
        }
        
        return reminders
    }
    
    func deleteReminder(_ reminder: ReminderEntry) async throws {
        let recordID = CKRecord.ID(recordName: reminder.id.uuidString)
        try await privateDatabase.deleteRecord(withID: recordID)
    }
    
    // MARK: - Person Operations
    
    func savePerson(_ person: PersonEntry) async throws {
        let record = personToRecord(person)
        try await privateDatabase.save(record)
    }
    
    func fetchPeople() async throws -> [PersonEntry] {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: personRecordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        
        let results = try await privateDatabase.records(matching: query)
        
        var people: [PersonEntry] = []
        for (_, result) in results.matchResults {
            switch result {
            case .success(let record):
                if let person = recordToPerson(record) {
                    people.append(person)
                }
            case .failure(let error):
                print("Error fetching person: \(error)")
            }
        }
        
        return people
    }
    
    func deletePerson(_ person: PersonEntry) async throws {
        let recordID = CKRecord.ID(recordName: person.id.uuidString)
        try await privateDatabase.deleteRecord(withID: recordID)
    }
    
    // MARK: - CBT Entry Operations
    
    func saveCBTEntry(_ entry: CBTEntry) async throws {
        let record = cbtEntryToRecord(entry)
        try await privateDatabase.save(record)
    }
    
    func fetchCBTEntries() async throws -> [CBTEntry] {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: cbtEntryRecordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        
        let results = try await privateDatabase.records(matching: query)
        
        var entries: [CBTEntry] = []
        for (_, result) in results.matchResults {
            switch result {
            case .success(let record):
                if let entry = recordToCBTEntry(record) {
                    entries.append(entry)
                }
            case .failure(let error):
                print("Error fetching CBT entry: \(error)")
            }
        }
        
        return entries
    }
    
    func deleteCBTEntry(_ entry: CBTEntry) async throws {
        let recordID = CKRecord.ID(recordName: entry.id.uuidString)
        try await privateDatabase.deleteRecord(withID: recordID)
    }
    
    func deleteAllCBTEntries() async throws {
        let entries = try await fetchCBTEntries()
        for entry in entries {
            try await deleteCBTEntry(entry)
        }
    }
    
    // MARK: - Batch Operations
    
    func saveReminders(_ reminders: [ReminderEntry]) async throws {
        let records = reminders.map { reminderToRecord($0) }
        
        // CloudKit has a limit of 400 operations per request
        let batchSize = 400
        for i in stride(from: 0, to: records.count, by: batchSize) {
            let batch = Array(records[i..<min(i + batchSize, records.count)])
            let (saveResults, _) = try await privateDatabase.modifyRecords(saving: batch, deleting: [])
            
            // Check for errors
            for (_, result) in saveResults {
                if case .failure(let error) = result {
                    print("Error saving reminder: \(error)")
                }
            }
        }
    }
    
    func savePeople(_ people: [PersonEntry]) async throws {
        let records = people.map { personToRecord($0) }
        
        let batchSize = 400
        for i in stride(from: 0, to: records.count, by: batchSize) {
            let batch = Array(records[i..<min(i + batchSize, records.count)])
            let (saveResults, _) = try await privateDatabase.modifyRecords(saving: batch, deleting: [])
            
            for (_, result) in saveResults {
                if case .failure(let error) = result {
                    print("Error saving person: \(error)")
                }
            }
        }
    }
    
    func saveCBTEntries(_ entries: [CBTEntry]) async throws {
        let records = entries.map { cbtEntryToRecord($0) }
        
        let batchSize = 400
        for i in stride(from: 0, to: records.count, by: batchSize) {
            let batch = Array(records[i..<min(i + batchSize, records.count)])
            let (saveResults, _) = try await privateDatabase.modifyRecords(saving: batch, deleting: [])
            
            for (_, result) in saveResults {
                if case .failure(let error) = result {
                    print("Error saving CBT entry: \(error)")
                }
            }
        }
    }
    
    func saveTodos(_ todos: [TodoItem]) async throws {
        let records = todos.map { todoToRecord($0) }
        
        let batchSize = 400
        for i in stride(from: 0, to: records.count, by: batchSize) {
            let batch = Array(records[i..<min(i + batchSize, records.count)])
            let (saveResults, _) = try await privateDatabase.modifyRecords(saving: batch, deleting: [])
            
            for (_, result) in saveResults {
                if case .failure(let error) = result {
                    print("Error saving todo: \(error)")
                }
            }
        }
    }
    
    func fetchTodos() async throws -> [TodoItem] {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: todoRecordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        
        let results = try await privateDatabase.records(matching: query)
        
        var todos: [TodoItem] = []
        for (_, result) in results.matchResults {
            switch result {
            case .success(let record):
                if let todo = recordToTodo(record) {
                    todos.append(todo)
                }
            case .failure(let error):
                print("Error fetching todo: \(error)")
            }
        }
        
        return todos
    }
    
    // MARK: - Conversion Methods
    
    private func reminderToRecord(_ reminder: ReminderEntry) -> CKRecord {
        let recordID = CKRecord.ID(recordName: reminder.id.uuidString)
        let record = CKRecord(recordType: reminderRecordType, recordID: recordID)
        
        record["text"] = reminder.text as CKRecordValue
        record["date"] = reminder.date as CKRecordValue
        record["lastModified"] = reminder.lastModified as CKRecordValue
        
        return record
    }
    
    private func recordToReminder(_ record: CKRecord) -> ReminderEntry? {
        let idString = record.recordID.recordName
        guard let id = UUID(uuidString: idString),
              let text = record["text"] as? String,
              let date = record["date"] as? Date,
              let lastModified = record["lastModified"] as? Date else {
            return nil
        }
        
        return ReminderEntry(id: id, text: text, date: date, lastModified: lastModified)
    }
    
    private func personToRecord(_ person: PersonEntry) -> CKRecord {
        let recordID = CKRecord.ID(recordName: person.id.uuidString)
        let record = CKRecord(recordType: personRecordType, recordID: recordID)
        
        record["text"] = person.text as CKRecordValue
        record["date"] = person.date as CKRecordValue
        record["lastModified"] = person.lastModified as CKRecordValue
        
        return record
    }
    
    private func recordToPerson(_ record: CKRecord) -> PersonEntry? {
        let idString = record.recordID.recordName
        guard let id = UUID(uuidString: idString),
              let text = record["text"] as? String,
              let date = record["date"] as? Date,
              let lastModified = record["lastModified"] as? Date else {
            return nil
        }
        
        return PersonEntry(id: id, text: text, date: date, lastModified: lastModified)
    }
    
    private func todoToRecord(_ todo: TodoItem) -> CKRecord {
        let recordID = CKRecord.ID(recordName: todo.id.uuidString)
        let record = CKRecord(recordType: todoRecordType, recordID: recordID)
        
        record["text"] = todo.text as CKRecordValue
        record["isCompleted"] = (todo.isCompleted ? 1 : 0) as CKRecordValue
        record["date"] = todo.date as CKRecordValue
        
        return record
    }
    
    private func recordToTodo(_ record: CKRecord) -> TodoItem? {
        let idString = record.recordID.recordName
        guard let id = UUID(uuidString: idString),
              let text = record["text"] as? String,
              let isCompletedInt = record["isCompleted"] as? Int,
              let date = record["date"] as? Date else {
            return nil
        }
        
        return TodoItem(id: id, text: text, isCompleted: isCompletedInt == 1, date: date)
    }
    
    private func cbtEntryToRecord(_ entry: CBTEntry) -> CKRecord {
        let recordID = CKRecord.ID(recordName: entry.id.uuidString)
        let record = CKRecord(recordType: cbtEntryRecordType, recordID: recordID)
        
        record["situation"] = entry.situation as CKRecordValue
        record["challenge"] = entry.challenge as CKRecordValue
        record["alternative"] = entry.alternative as CKRecordValue
        record["notes"] = entry.notes as CKRecordValue
        record["date"] = entry.date as CKRecordValue
        record["lastModified"] = entry.lastModified as CKRecordValue
        
        // Store distortion IDs as strings
        let distortionIdStrings = entry.distortionIds.map { $0.uuidString }
        record["distortionIds"] = distortionIdStrings as CKRecordValue
        
        return record
    }
    
    private func recordToCBTEntry(_ record: CKRecord) -> CBTEntry? {
        let idString = record.recordID.recordName
        guard let id = UUID(uuidString: idString),
              let situation = record["situation"] as? String,
              let challenge = record["challenge"] as? String,
              let alternative = record["alternative"] as? String,
              let notes = record["notes"] as? String,
              let date = record["date"] as? Date,
              let lastModified = record["lastModified"] as? Date else {
            return nil
        }
        
        // Convert distortion ID strings back to UUIDs
        var distortionIds: [UUID] = []
        if let distortionIdStrings = record["distortionIds"] as? [String] {
            distortionIds = distortionIdStrings.compactMap { UUID(uuidString: $0) }
        }
        
        return CBTEntry(
            id: id,
            situation: situation,
            distortionIds: distortionIds,
            challenge: challenge,
            alternative: alternative,
            notes: notes,
            date: date,
            lastModified: lastModified
        )
    }
    
    // MARK: - Account Status
    
    func checkAccountStatus() async throws -> CKAccountStatus {
        return try await container.accountStatus()
    }
    
    func isCloudKitAvailable() async -> Bool {
        do {
            let status = try await checkAccountStatus()
            return status == .available
        } catch {
            print("Error checking CloudKit status: \(error)")
            return false
        }
    }
}

