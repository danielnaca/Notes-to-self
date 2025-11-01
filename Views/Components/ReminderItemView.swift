import SwiftUI

// 📗 Reminder Item: Individual reminder row in the list
struct ReminderItemView: View {
    let reminder: ReminderEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(reminder.text)
                .foregroundColor(AppColors.noteText)
        }
        .listRowBackground(AppColors.listBackground)
        .id(reminder.id)
    }
}

