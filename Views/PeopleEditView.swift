//
//  PeopleEditView.swift
//  Notes to self
//
//  Created by AI Assistant on 10/29/25.
//

import SwiftUI

// 📗 People Edit View: Navigation-style edit interface for people entries
struct PeopleEditView: View {
    @EnvironmentObject var store: NotesStore
    @Environment(\.dismiss) private var dismiss
    let note: Note
    @State private var editedText: String
    
    init(note: Note) {
        self.note = note
        self._editedText = State(initialValue: note.text)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Date info section
            VStack(alignment: .leading, spacing: 8) {
                Text("Created: \(DateFormatter.peopleFormatter.string(from: note.date))")
                    .font(.caption)
                    .foregroundColor(AppColors.secondaryText)
                    .padding(.horizontal)
                    .padding(.top)
            }
            
            // Text editor with styled text
            StyledTextEditor(text: $editedText)
                .padding(.horizontal)
            
            Spacer()
        }
        .background(AppColors.background)
        .navigationTitle(note.text.isEmpty ? "New Person" : "Edit Person")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveChanges()
                    dismiss()
                }
                .foregroundColor(AppColors.accent)
                .disabled(editedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
    
    private func saveChanges() {
        let trimmedText = editedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        if let index = store.people.firstIndex(where: { $0.id == note.id }) {
            // Update existing person
            let updatedNote = Note(
                id: note.id,
                text: trimmedText,
                date: note.date,
                lastModified: Date()
            )
            store.people[index] = updatedNote
        } else {
            // Add new person (for + button created entries)
            let newNote = Note(
                id: note.id,
                text: trimmedText,
                date: Date(),
                lastModified: Date()
            )
            store.people.insert(newNote, at: 0)
        }
    }
}

// 📗 Styled Text Editor: First line bold, rest regular
struct StyledTextEditor: UIViewRepresentable {
    @Binding var text: String
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = UIFont.systemFont(ofSize: 17)
        textView.backgroundColor = .white
        textView.textColor = UIColor(AppColors.noteText)
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            let selectedRange = uiView.selectedTextRange
            uiView.attributedText = styledAttributedString(from: text)
            if let range = selectedRange {
                uiView.selectedTextRange = range
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func styledAttributedString(from text: String) -> NSAttributedString {
        let lines = text.components(separatedBy: "\n")
        let attributedString = NSMutableAttributedString()
        
        for (index, line) in lines.enumerated() {
            let lineText = index < lines.count - 1 ? line + "\n" : line
            
            if index == 0 {
                // First line: bold
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 17),
                    .foregroundColor: UIColor(AppColors.noteText)
                ]
                attributedString.append(NSAttributedString(string: lineText, attributes: attrs))
            } else {
                // Rest: regular
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 17),
                    .foregroundColor: UIColor(AppColors.noteText)
                ]
                attributedString.append(NSAttributedString(string: lineText, attributes: attrs))
            }
        }
        
        return attributedString
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: StyledTextEditor
        
        init(_ parent: StyledTextEditor) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            
            // Reapply styling
            let cursorPosition = textView.selectedRange
            textView.attributedText = parent.styledAttributedString(from: textView.text)
            textView.selectedRange = cursorPosition
        }
    }
}

// MARK: - Date Formatter Extension
extension DateFormatter {
    static let peopleFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

#Preview {
    NavigationView {
        PeopleEditView(note: Note(text: "Sample person"))
            .environmentObject(NotesStore())
    }
}

