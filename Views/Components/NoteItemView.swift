import SwiftUI

// 📗 Note Item: Individual note row in the list
struct NoteItemView: View {
    let note: Note
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(note.text)
                .foregroundColor(AppColors.noteText)
        }
        .listRowBackground(AppColors.listBackground)
        .id(note.id)
    }
} 