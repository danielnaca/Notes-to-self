import SwiftUI

// 📗 Main Content View: Primary interface for the Notes to Self app
struct ContentView: View {
    @EnvironmentObject var store: NotesStore
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Input section
                HStack {
                    ExpandingTextView(text: $store.newNote, placeholder: "What's on your mind?")
                        .frame(minHeight: 44)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(AppColors.inputBackground)
                        .cornerRadius(22)
                    
                    Button(action: store.addNote) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(AppColors.accent)
                    }
                    .disabled(store.newNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
                .background(AppColors.background)
                
                // Notes list
                if store.notes.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "note.text")
                            .font(.system(size: 48))
                            .foregroundColor(AppColors.secondaryText)
                        Text("No notes yet")
                            .font(.title2)
                            .foregroundColor(AppColors.secondaryText)
                        Text("Add your first note above")
                            .font(.body)
                            .foregroundColor(AppColors.tertiaryText)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(store.notes) { note in
                            NoteItemView(note: note)
                        }
                        .onDelete(perform: store.delete)
                    }
                    .listStyle(PlainListStyle())
                    .background(AppColors.listBackground)
                }
            }
            .background(AppColors.background)
            .navigationTitle("Notes to Self")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape")
                            .foregroundColor(AppColors.accent)
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(NotesStore())
} 