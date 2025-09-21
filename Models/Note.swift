import Foundation

// 📗 Note Entry: Individual note data structure
struct Note: Identifiable, Codable, Equatable {
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