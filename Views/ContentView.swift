import SwiftUI

// 📗 Main Content View: Primary interface for the Notes to Self app
struct ContentView: View {
    @EnvironmentObject var store: NotesStore
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Entries
            EntriesView()
                .environmentObject(store)
                .tabItem {
                    Image(systemName: "note.text")
                    Text("Entries")
                }
                .tag(0)
            
            // Tab 2: People
            PeopleView()
                .tabItem {
                    Image(systemName: "person.2")
                    Text("People")
                }
                .tag(1)
            
            // Tab 3: Alarms
            AlarmsView()
                .tabItem {
                    Image(systemName: "alarm")
                    Text("Alarms")
                }
                .tag(2)
            
            // Tab 4: Settings
            SettingsView()
                .environmentObject(store)
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("Settings")
                }
                .tag(3)
        }
        .tint(AppColors.accent)
    }
}

#Preview {
    ContentView()
        .environmentObject(NotesStore())
} 