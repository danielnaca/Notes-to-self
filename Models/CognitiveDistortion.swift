//
//  CognitiveDistortion.swift
//  Notes to self
//
//  Created by AI Assistant on 10/31/25.
//

import Foundation

// 📗 Cognitive Distortion: Represents a type of thinking error in CBT
struct CognitiveDistortion: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let emoji: String
    let title: String
    let description: String
    
    init(id: UUID = UUID(), emoji: String, title: String, description: String) {
        self.id = id
        self.emoji = emoji
        self.title = title
        self.description = description
    }
}

// MARK: - Common Cognitive Distortions
extension CognitiveDistortion {
    static let allDistortions: [CognitiveDistortion] = [
        CognitiveDistortion(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            emoji: "⚫️",
            title: "All-or-Nothing Thinking",
            description: "Seeing things in black and white categories. If your performance falls short of perfect, you see yourself as a total failure."
        ),
        CognitiveDistortion(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            emoji: "🔮",
            title: "Overgeneralization",
            description: "Seeing a single negative event as a never-ending pattern of defeat."
        ),
        CognitiveDistortion(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            emoji: "🔍",
            title: "Mental Filter",
            description: "Picking out a single negative detail and dwelling on it exclusively so your vision of reality becomes darkened."
        ),
        CognitiveDistortion(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
            emoji: "❌",
            title: "Disqualifying the Positive",
            description: "Rejecting positive experiences by insisting they 'don't count' for some reason."
        ),
        CognitiveDistortion(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!,
            emoji: "🧠",
            title: "Jumping to Conclusions",
            description: "Making negative interpretations without actual evidence. Mind reading or fortune telling."
        ),
        CognitiveDistortion(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000006")!,
            emoji: "🔬",
            title: "Magnification or Minimization",
            description: "Exaggerating the importance of things (like mistakes) or inappropriately shrinking things until they appear tiny."
        ),
        CognitiveDistortion(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000007")!,
            emoji: "💭",
            title: "Emotional Reasoning",
            description: "Assuming that your negative emotions reflect the way things really are: 'I feel it, therefore it must be true.'"
        ),
        CognitiveDistortion(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000008")!,
            emoji: "📋",
            title: "Should Statements",
            description: "Trying to motivate yourself with 'shoulds' and 'shouldn'ts', as if you need to be whipped and punished before you can do anything."
        ),
        CognitiveDistortion(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000009")!,
            emoji: "🏷️",
            title: "Labeling",
            description: "An extreme form of overgeneralization. Instead of describing an error, you attach a negative label to yourself."
        ),
        CognitiveDistortion(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000010")!,
            emoji: "👈",
            title: "Personalization",
            description: "Seeing yourself as the cause of some negative external event for which you were not primarily responsible."
        )
    ]
}

