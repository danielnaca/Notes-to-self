import Foundation
import SwiftUI
import CloudKit

// 📗 People Data Store: Manages people data and operations
class PeopleStore: ObservableObject {
    @Published var people: [PersonEntry] = [] {
        didSet { savePeople() }
    }
    
    private let appGroupID = "group.co.uk.cursive.NotesToSelf"
    private let peopleKey = "people"
    private let cloudKit = CloudKitManager.shared
    private var isSyncing = false
    
    init() {
        loadFromCloudKit()
    }
    
    func addPerson(_ person: PersonEntry) {
        people.insert(person, at: 0)
    }
    
    func updatePerson(_ person: PersonEntry) {
        if let index = people.firstIndex(where: { $0.id == person.id }) {
            var updatedPerson = person
            updatedPerson = PersonEntry(
                id: updatedPerson.id,
                text: updatedPerson.text,
                date: updatedPerson.date,
                lastModified: Date()
            )
            people[index] = updatedPerson
        }
    }
    
    func deletePerson(at offsets: IndexSet) {
        people.remove(atOffsets: offsets)
    }
    
    // MARK: - CloudKit Sync Methods
    
    private func loadFromCloudKit() {
        Task {
            do {
                guard await cloudKit.isCloudKitAvailable() else {
                    print("CloudKit not available, loading people from UserDefaults fallback")
                    await MainActor.run {
                        loadFromUserDefaults()
                    }
                    return
                }
                
                let fetchedPeople = try await cloudKit.fetchPeople()
                
                await MainActor.run {
                    isSyncing = true
                    self.people = fetchedPeople
                    isSyncing = false
                    print("Loaded \(fetchedPeople.count) people from CloudKit")
                }
            } catch {
                print("Error loading people from CloudKit: \(error)")
                await MainActor.run {
                    loadFromUserDefaults()
                }
            }
        }
    }
    
    private func savePeople() {
        guard !isSyncing else { return }
        
        // Always save to UserDefaults (not needed for widget, but kept for consistency)
        savePeopleToUserDefaults()
        
        Task {
            do {
                guard await cloudKit.isCloudKitAvailable() else {
                    print("CloudKit not available, UserDefaults already saved")
                    return
                }
                
                try await cloudKit.savePeople(people)
                print("Saved \(people.count) people to CloudKit")
            } catch {
                print("Error saving people to CloudKit: \(error)")
            }
        }
    }
    
    // MARK: - UserDefaults Fallback
    
    private func loadFromUserDefaults() {
        guard let ud = UserDefaults(suiteName: appGroupID) else { return }
        
        if let data = ud.data(forKey: peopleKey),
           let decoded = try? JSONDecoder().decode([PersonEntry].self, from: data) {
            people = decoded
        }
        
        print("Loaded from UserDefaults: \(people.count) people")
    }
    
    private func savePeopleToUserDefaults() {
        guard let ud = UserDefaults(suiteName: appGroupID) else { return }
        if let data = try? JSONEncoder().encode(people) {
            ud.set(data, forKey: peopleKey)
        }
    }
}

