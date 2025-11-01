import SwiftUI

// 📗 Main Content View: Primary interface for the Notes to Self app
struct ContentView: View {
    @EnvironmentObject var remindersStore: RemindersStore
    @EnvironmentObject var peopleStore: PeopleStore
    @EnvironmentObject var cbtStore: CBTStore
    @EnvironmentObject var todoStore: TodoStore
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Reminders
            RemindersView()
                .environmentObject(remindersStore)
                .tabItem {
                    Image(systemName: "note.text")
                    Text("Reminders")
                }
                .tag(0)
            
            // Tab 2: People
            PeopleView()
                .environmentObject(peopleStore)
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
                .environmentObject(remindersStore)
                .environmentObject(peopleStore)
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
                .tag(3)
            
            // Tab 5: Settings
            SettingsView()
                .environmentObject(remindersStore)
                .environmentObject(peopleStore)
                .environmentObject(cbtStore)
                .environmentObject(todoStore)
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
        .environmentObject(RemindersStore())
        .environmentObject(PeopleStore())
        .environmentObject(CBTStore())
        .environmentObject(TodoStore())
} 