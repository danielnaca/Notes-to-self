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
    private let noteRecordType = "Note"
    private let cbtEntryRecordType = "CBTEntry"
    
    private init() {
        container = CKContainer.default()
        privateDatabase = container.privateCloudDatabase
    }
    
    // MARK: - Note Operations
    
    func saveNote(_ note: Note, isPersonNote: Bool) async throws {
        let record = noteToRecord(note, isPersonNote: isPersonNote)
        try await privateDatabase.save(record)
    }
    
    func fetchNotes(isPersonNote: Bool) async throws -> [Note] {
        let predicate = NSPredicate(format: "isPersonNote == %@", NSNumber(value: isPersonNote))
        let query = CKQuery(recordType: noteRecordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        
        let results = try await privateDatabase.records(matching: query)
        
        var notes: [Note] = []
        for (_, result) in results.matchResults {
            switch result {
            case .success(let record):
                if let note = recordToNote(record) {
                    notes.append(note)
                }
            case .failure(let error):
                print("Error fetching note: \(error)")
            }
        }
        
        return notes
    }
    
    func deleteNote(_ note: Note) async throws {
        let recordID = CKRecord.ID(recordName: note.id.uuidString)
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
    
    func saveNotes(_ notes: [Note], isPersonNote: Bool) async throws {
        let records = notes.map { noteToRecord($0, isPersonNote: isPersonNote) }
        
        // CloudKit has a limit of 400 operations per request
        let batchSize = 400
        for i in stride(from: 0, to: records.count, by: batchSize) {
            let batch = Array(records[i..<min(i + batchSize, records.count)])
            let (saveResults, _) = try await privateDatabase.modifyRecords(saving: batch, deleting: [])
            
            // Check for errors
            for (_, result) in saveResults {
                if case .failure(let error) = result {
                    print("Error saving note: \(error)")
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
    
    // MARK: - Conversion Methods
    
    private func noteToRecord(_ note: Note, isPersonNote: Bool) -> CKRecord {
        let recordID = CKRecord.ID(recordName: note.id.uuidString)
        let record = CKRecord(recordType: noteRecordType, recordID: recordID)
        
        record["text"] = note.text as CKRecordValue
        record["date"] = note.date as CKRecordValue
        record["lastModified"] = note.lastModified as CKRecordValue
        record["isPersonNote"] = (isPersonNote ? 1 : 0) as CKRecordValue
        
        return record
    }
    
    private func recordToNote(_ record: CKRecord) -> Note? {
        guard let idString = record.recordID.recordName,
              let id = UUID(uuidString: idString),
              let text = record["text"] as? String,
              let date = record["date"] as? Date,
              let lastModified = record["lastModified"] as? Date else {
            return nil
        }
        
        return Note(id: id, text: text, date: date, lastModified: lastModified)
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
        guard let idString = record.recordID.recordName,
              let id = UUID(uuidString: idString),
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

