//
//  CBTEntry.swift
//  Notes to self
//
//  Created by AI Assistant on 10/31/25.
//

import Foundation

// 📗 CBT Entry: Represents a cognitive behavioral therapy thought record
struct CBTEntry: Identifiable, Codable, Hashable {
    let id: UUID
    var situation: String
    var distortionIds: [UUID] // References to CognitiveDistortion IDs
    var challenge: String
    var alternative: String
    var notes: String
    let date: Date
    var lastModified: Date
    
    init(
        id: UUID = UUID(),
        situation: String = "",
        distortionIds: [UUID] = [],
        challenge: String = "",
        alternative: String = "",
        notes: String = "",
        date: Date = Date(),
        lastModified: Date = Date()
    ) {
        self.id = id
        self.situation = situation
        self.distortionIds = distortionIds
        self.challenge = challenge
        self.alternative = alternative
        self.notes = notes
        self.date = date
        self.lastModified = lastModified
    }
}

