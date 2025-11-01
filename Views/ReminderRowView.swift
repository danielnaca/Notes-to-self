//
//  ReminderRowView.swift
//  Notes to self
//
//  Created by AI Assistant on 10/19/25.
//

import SwiftUI

// 📗 Reminder Row View: Individual row showing reminder preview
struct ReminderRowView: View {
    let reminder: ReminderEntry
    
    private var preview: String {
        // Show first few lines as preview, truncated
        let lines = reminder.text.components(separatedBy: .newlines)
        let previewLines = Array(lines.prefix(3)).joined(separator: " ")
        return previewLines.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(preview)
                .font(.body)
                .foregroundColor(AppColors.noteText)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
            
            Text(DateFormatter.remindersFormatter.string(from: reminder.date))
                .font(.caption)
                .foregroundColor(AppColors.secondaryText)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

// MARK: - Date Formatter Extension
extension DateFormatter {
    static let remindersFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

#Preview {
    @Previewable @State var sampleReminder = ReminderEntry(text: "This is a sample reminder with multiple lines\nSecond line here\nThird line for testing")
    ReminderRowView(reminder: sampleReminder)
        .padding()
}

