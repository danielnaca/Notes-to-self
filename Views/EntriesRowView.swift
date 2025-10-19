//
//  EntriesRowView.swift
//  Notes to self
//
//  Created by AI Assistant on 10/19/25.
//

import SwiftUI

// 📗 Entries Row View: Individual row showing entry preview
struct EntriesRowView: View {
    let note: Note
    
    private var preview: String {
        // Show first few lines as preview, truncated
        let lines = note.text.components(separatedBy: .newlines)
        let previewLines = Array(lines.prefix(3)).joined(separator: " ")
        return previewLines.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(preview)
                    .font(.body)
                    .foregroundColor(AppColors.noteText)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                
                Text(DateFormatter.entriesFormatter.string(from: note.date))
                    .font(.caption)
                    .foregroundColor(AppColors.secondaryText)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(AppColors.tertiaryText)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

// MARK: - Date Formatter Extension
extension DateFormatter {
    static let entriesFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

#Preview {
    @Previewable @State var sampleNote = Note(text: "This is a sample entry with multiple lines\nSecond line here\nThird line for testing")
    EntriesRowView(note: sampleNote)
        .padding()
}

