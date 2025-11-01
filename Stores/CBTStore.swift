//
//  CBTStore.swift
//  Notes to self
//
//  Created by AI Assistant on 10/31/25.
//

import Foundation
import SwiftUI
import CloudKit

// 📗 CBT Store: Manages CBT entries with autosave
class CBTStore: ObservableObject {
    @Published var entries: [CBTEntry] = [] {
        didSet { save() }
    }
    
    private let appGroupID = "group.co.uk.cursive.NotesToSelf"
    private let entriesKey = "cbtEntries"
    private let cloudKit = CloudKitManager.shared
    private var isSyncing = false
    
    init() {
        loadFromCloudKit()
    }
    
    // MARK: - Mock Data Generation (Development Only)
    func generateMockEntries() {
        let situations = [
            "Coworker didn't respond to my email",
            "Friend cancelled plans last minute",
            "Got negative feedback on my project",
            "Made a mistake in front of everyone",
            "Someone looked at me weird on the bus",
            "Didn't get invited to the party",
            "My presentation didn't go as planned",
            "Text message left on read",
            "Boss seemed annoyed with me",
            "Forgot an important deadline",
            "Said something awkward in the meeting",
            "Post didn't get many likes",
            "Interview didn't go well",
            "Partner seemed distant today",
            "Failed to meet my own expectations",
            "Someone interrupted me while speaking",
            "Didn't understand something everyone else got",
            "Made a silly typo in an important document",
            "Felt left out of a conversation",
            "Couldn't think of what to say"
        ]
        
        let challenges = [
            "Maybe they're just busy and haven't had time to respond",
            "One mistake doesn't define my entire worth",
            "I'm probably overthinking this situation",
            "Other people likely didn't notice or already forgot",
            "This feeling will pass like it always does",
            "I've handled similar situations well before",
            "There could be many explanations I haven't considered",
            "My anxiety is amplifying a small thing",
            "Most people are focused on themselves, not judging me",
            "I'm being harder on myself than I need to be"
        ]
        
        let alternatives = [
            "I can reach out again later if needed. It's not a reflection of my worth.",
            "Everyone makes mistakes. This is a chance to learn and grow.",
            "I did my best with what I knew at the time.",
            "This is one moment in my life, not the whole story.",
            "I'm allowed to be imperfect and still be valued.",
            "People care less about my mistakes than I think.",
            "I can handle uncertainty and discomfort.",
            "My feelings are valid but they're not facts.",
            "I'm doing better than my anxiety tells me.",
            "This too shall pass, and I'll be okay."
        ]
        
        let notes = [
            "Felt better after writing this down",
            "Need to remember this pattern",
            "Similar to last week's situation",
            "Practiced deep breathing, it helped",
            "Talked to a friend about it",
            "Went for a walk to clear my head",
            "Reminded myself of past successes",
            "This feeling passed within an hour",
            "Sleep helped put things in perspective",
            ""
        ]
        
        // Generate 50 entries over past 120 days
        for _ in 0..<50 {
            let daysAgo = Int.random(in: 0...120)
            let hoursOffset = Int.random(in: 0...23)
            let minutesOffset = Int.random(in: 0...59)
            
            let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
            let finalDate = Calendar.current.date(byAdding: .hour, value: -hoursOffset, to: date)!
            let entryDate = Calendar.current.date(byAdding: .minute, value: -minutesOffset, to: finalDate)!
            
            // Random distortions (1-3)
            let numDistortions = Int.random(in: 1...3)
            let allDistortions = CognitiveDistortion.allDistortions
            let selectedDistortions = (0..<numDistortions).map { _ in
                allDistortions.randomElement()!.id
            }
            
            let entry = CBTEntry(
                situation: situations.randomElement()!,
                distortionIds: selectedDistortions,
                challenge: challenges.randomElement()!,
                alternative: alternatives.randomElement()!,
                notes: notes.randomElement()!,
                date: entryDate,
                lastModified: entryDate
            )
            
            entries.append(entry)
        }
        
        // Sort by date (newest first)
        entries.sort { $0.date > $1.date }
    }
    
    func updateEntry(_ entry: CBTEntry) {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            var updatedEntry = entry
            updatedEntry.lastModified = Date()
            entries[index] = updatedEntry
        } else {
            // New entry
            entries.insert(entry, at: 0) // Newest first
        }
    }
    
    func deleteEntry(_ entry: CBTEntry) {
        entries.removeAll(where: { $0.id == entry.id })
    }
    
    func deleteAllEntries() {
        Task {
            do {
                if await cloudKit.isCloudKitAvailable() {
                    try await cloudKit.deleteAllCBTEntries()
                }
            } catch {
                print("Error deleting all CBT entries from CloudKit: \(error)")
            }
        }
        entries.removeAll()
    }
    
    func getDistortions(for entry: CBTEntry) -> [CognitiveDistortion] {
        return entry.distortionIds.compactMap { id in
            CognitiveDistortion.allDistortions.first(where: { $0.id == id })
        }
    }
    
    // MARK: - CloudKit Sync Methods
    
    private func loadFromCloudKit() {
        Task {
            do {
                // Check if CloudKit is available
                guard await cloudKit.isCloudKitAvailable() else {
                    print("CloudKit not available, loading from UserDefaults fallback")
                    await MainActor.run {
                        loadFromUserDefaults()
                    }
                    return
                }
                
                // Fetch from CloudKit
                let fetchedEntries = try await cloudKit.fetchCBTEntries()
                
                await MainActor.run {
                    isSyncing = true
                    self.entries = fetchedEntries
                    isSyncing = false
                    print("Loaded \(fetchedEntries.count) CBT entries from CloudKit")
                }
            } catch {
                print("Error loading from CloudKit: \(error)")
                await MainActor.run {
                    loadFromUserDefaults()
                }
            }
        }
    }
    
    private func save() {
        guard !isSyncing else { return }
        
        Task {
            do {
                guard await cloudKit.isCloudKitAvailable() else {
                    print("CloudKit not available, saving to UserDefaults fallback")
                    await MainActor.run {
                        saveToUserDefaults()
                    }
                    return
                }
                
                try await cloudKit.saveCBTEntries(entries)
                print("Saved \(entries.count) CBT entries to CloudKit")
            } catch {
                print("Error saving to CloudKit: \(error)")
                await MainActor.run {
                    saveToUserDefaults()
                }
            }
        }
    }
    
    // MARK: - UserDefaults Fallback
    
    private func loadFromUserDefaults() {
        guard let ud = UserDefaults(suiteName: appGroupID) else { return }
        if let data = ud.data(forKey: entriesKey),
           let decoded = try? JSONDecoder().decode([CBTEntry].self, from: data) {
            entries = decoded
            print("Loaded \(entries.count) CBT entries from UserDefaults")
        }
    }
    
    private func saveToUserDefaults() {
        guard let ud = UserDefaults(suiteName: appGroupID) else { return }
        if let data = try? JSONEncoder().encode(entries) {
            ud.set(data, forKey: entriesKey)
        }
    }
}

