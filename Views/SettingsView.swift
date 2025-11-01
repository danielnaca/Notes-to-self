//
//  SettingsView.swift
//  Notes to self
//
//  Created by Daniel Nacamuli on 6/15/25.
//

import SwiftUI

// 📗 Complete App Data: Contains all data for export/import
struct CompleteAppData: Codable {
    let reminders: [ReminderEntry]
    let people: [PersonEntry]
    let cbtEntries: [CBTEntry]
    let exportDate: Date
    
    init(reminders: [ReminderEntry], people: [PersonEntry], cbtEntries: [CBTEntry]) {
        self.reminders = reminders
        self.people = people
        self.cbtEntries = cbtEntries
        self.exportDate = Date()
    }
}

// 📗 Settings Screen: Configuration screen for app preferences
struct SettingsView: View {
    @EnvironmentObject var remindersStore: RemindersStore
    @EnvironmentObject var peopleStore: PeopleStore
    @EnvironmentObject var cbtStore: CBTStore
    @EnvironmentObject var todoStore: TodoStore
    @State private var notificationsPerWeek: Double = 2
    @State private var notificationsEnabled: Bool = true
    @State private var showingImportView = false
    @State private var showCopyAlert = false
    @State private var copyAlertMessage = ""
    @State private var showDeleteAllAlert = false
    @State private var showImportAlert = false
    @State private var importAlertMessage = ""
    @State private var showingUIVocabulary = false
    @State private var showingTodoList = false
    
    private var isAllDataEmpty: Bool {
        remindersStore.reminders.isEmpty && peopleStore.people.isEmpty && cbtStore.entries.isEmpty
    }
    
    // MARK: - Sections
    
    private var developerSection: some View {
        Section("Developer") {
            Button("UI Vocabulary") {
                showingUIVocabulary = true
            }
            
            Button("Todo List") {
                showingTodoList = true
            }
        }
    }
    
    private var notificationsSection: some View {
        Section("Notifications") {
            Toggle("Enable Notifications", isOn: $notificationsEnabled)
            
            if notificationsEnabled {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notifications per week: \(Int(notificationsPerWeek))")
                    Slider(value: $notificationsPerWeek, in: 1...7, step: 1)
                }
            }
        }
    }
    
    private var dataManagementSection: some View {
        Section("Data Management") {
            Button("Export All Data") {
                exportAllData()
            }
            .disabled(isAllDataEmpty)
            
            Button("Import All Data") {
                showingImportView = true
            }
            
            Button("Delete All Data") {
                showDeleteAllAlert = true
            }
            .foregroundColor(.red)
            .disabled(isAllDataEmpty)
        }
    }
    
    private var statisticsSection: some View {
        Section("Statistics") {
            HStack {
                Text("Total Reminders")
                Spacer()
                Text("\(remindersStore.reminders.count)")
                    .foregroundColor(AppColors.secondaryText)
            }
            
            HStack {
                Text("Total People")
                Spacer()
                Text("\(peopleStore.people.count)")
                    .foregroundColor(AppColors.secondaryText)
            }
            
            HStack {
                Text("Total CBT Entries")
                Spacer()
                Text("\(cbtStore.entries.count)")
                    .foregroundColor(AppColors.secondaryText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            settingsForm
        }
    }
    
    private var settingsForm: some View {
        Form {
            developerSection
            notificationsSection
            dataManagementSection
            statisticsSection
        }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingImportView) {
                ImportDataView()
                    .environmentObject(remindersStore)
                    .environmentObject(peopleStore)
                    .environmentObject(cbtStore)
            }
            .sheet(isPresented: $showingUIVocabulary) {
                UIVocabularyView()
            }
            .sheet(isPresented: $showingTodoList) {
                TodoListView()
                    .environmentObject(todoStore)
            }
            .alert("Copied", isPresented: $showCopyAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(copyAlertMessage)
            }
            .alert("Import/Export", isPresented: $remindersStore.showImportExportAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(remindersStore.importExportMessage)
            }
            .alert("Delete All Data?", isPresented: $showDeleteAllAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete All", role: .destructive) {
                    deleteAllData()
                }
            } message: {
                deleteAllAlertMessage()
            }
            .alert("Import Status", isPresented: $showImportAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(importAlertMessage)
            }
    }
    
    // MARK: - Export/Import/Delete Functions
    
    private func deleteAllAlertMessage() -> Text {
        let remindersCount = remindersStore.reminders.count
        let peopleCount = peopleStore.people.count
        let cbtCount = cbtStore.entries.count
        let totalItems = remindersCount + peopleCount + cbtCount
        
        return Text("This will permanently delete ALL data:\n• \(remindersCount) reminders\n• \(peopleCount) people\n• \(cbtCount) CBT entries\n\nTotal: \(totalItems) items\n\nThis action cannot be undone.")
    }
    
    private func deleteAllData() {
        // Delete all reminders
        remindersStore.reminders.removeAll()
        
        // Delete all people
        peopleStore.people.removeAll()
        
        // Delete all CBT entries
        cbtStore.deleteAllEntries()
    }
    
    private func exportAllData() {
        let completeData = CompleteAppData(
            reminders: remindersStore.reminders,
            people: peopleStore.people,
            cbtEntries: cbtStore.entries
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        guard let data = try? encoder.encode(completeData),
              let jsonString = String(data: data, encoding: .utf8) else {
            copyAlertMessage = "Failed to export data"
            showCopyAlert = true
            return
        }
        
        UIPasteboard.general.string = jsonString
        
        let remindersCount = remindersStore.reminders.count
        let peopleCount = peopleStore.people.count
        let cbtCount = cbtStore.entries.count
        let totalItems = remindersCount + peopleCount + cbtCount
        copyAlertMessage = "Exported \(totalItems) items (\(remindersCount) reminders, \(peopleCount) people, \(cbtCount) CBT) to clipboard"
        showCopyAlert = true
    }
}


// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    SettingsView()
        .environmentObject(RemindersStore())
        .environmentObject(PeopleStore())
        .environmentObject(CBTStore())
        .environmentObject(TodoStore())
} 