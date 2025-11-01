//
//  TodoItem.swift
//  Notes to self
//
//  Created by AI Assistant
//

import Foundation

struct TodoItem: Identifiable, Codable, Hashable {
    let id: UUID
    var text: String
    var isCompleted: Bool
    var date: Date
    
    init(id: UUID = UUID(), text: String, isCompleted: Bool = false, date: Date = Date()) {
        self.id = id
        self.text = text
        self.isCompleted = isCompleted
        self.date = date
    }
}

