import SwiftUI

// 📗 Main Content View: Primary interface for the Notes to Self app
struct ContentView: View {
    @EnvironmentObject var store: NotesStore
    @EnvironmentObject var cbtStore: CBTStore
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
            
            // Tab 3: CBT
            CBTListView()
                .environmentObject(cbtStore)
                .tabItem {
                    Image(systemName: "brain.head.profile")
                    Text("CBT")
                }
                .tag(2)
            
            // Tab 4: Search
            SearchView(isActive: Binding(
                get: { selectedTab == 3 },
                set: { _ in }
            ))
                .environmentObject(store)
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
                .tag(3)
            
            // Tab 5: Settings
            SettingsView()
                .environmentObject(store)
                .environmentObject(cbtStore)
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("Settings")
                }
                .tag(4)
        }
        .tint(AppColors.accent)
    }
}

#Preview {
    ContentView()
        .environmentObject(NotesStore())
        .environmentObject(CBTStore())
} 