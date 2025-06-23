import Foundation

// 📗 Note Entry: Individual note data structure
struct Note: Identifiable, Codable, Equatable {
    let id: UUID
    let text: String
    let date: Date
    
    init(id: UUID = UUID(), text: String, date: Date = Date()) {
        self.id = id
        self.text = text
        self.date = date
    }
} 