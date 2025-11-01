//
//  UIVocabularyView.swift
//  Notes to self
//
//  Created by AI Assistant
//

import SwiftUI

struct UIVocabularyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Entries Section") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Input Bar")
                            .font(.headline)
                        Text("Bottom text field area with send button")
                            .font(.caption)
                            .foregroundColor(AppColors.secondaryText)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Message Bubble")
                            .font(.headline)
                        Text("Individual entry in the list")
                            .font(.caption)
                            .foregroundColor(AppColors.secondaryText)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Messages Area")
                            .font(.headline)
                        Text("Scrollable section showing all entries")
                            .font(.caption)
                            .foregroundColor(AppColors.secondaryText)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("UI Vocabulary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.accent)
                }
            }
        }
    }
}

#Preview {
    UIVocabularyView()
}

