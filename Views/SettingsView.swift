//
//  SettingsView.swift
//  Notes to self
//
//  Created by Daniel Nacamuli on 6/15/25.
//

import SwiftUI

// 📗 Complete App Data: Contains all data for export/import
struct CompleteAppData: Codable {
    let entries: [Note]
    let people: [Note]
    let cbtEntries: [CBTEntry]
    let exportDate: Date
    
    init(entries: [Note], people: [Note], cbtEntries: [CBTEntry]) {
        self.entries = entries
        self.people = people
        self.cbtEntries = cbtEntries
        self.exportDate = Date()
    }
}

// 📗 Settings Screen: Configuration screen for app preferences
struct SettingsView: View {
    @EnvironmentObject var store: NotesStore
    @EnvironmentObject var cbtStore: CBTStore
    @State private var notificationsPerWeek: Double = 2
    @State private var notificationsEnabled: Bool = true
    @State private var showingImportView = false
    @State private var showCopyAlert = false
    @State private var copyAlertMessage = ""
    @State private var showDeleteCBTAlert = false
    @State private var showImportAlert = false
    @State private var importAlertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("UI Vocabulary") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Input Bar: Bottom text field area with send button")
                            .font(.caption)
                        Text("Message Bubble: Individual entry in the list")
                            .font(.caption)
                        Text("Messages Area: Scrollable section showing all entries")
                            .font(.caption)
                    }
                    .foregroundColor(AppColors.secondaryText)
                    .padding(.vertical, 4)
                }
                
                Section("Notifications") {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                    
                    if notificationsEnabled {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notifications per week: \(Int(notificationsPerWeek))")
                            Slider(value: $notificationsPerWeek, in: 1...7, step: 1)
                        }
                    }
                }
                
                Section("Data Management") {
                    Button("Export All Data") {
                        exportAllData()
                    }
                    .disabled(store.notes.isEmpty && store.people.isEmpty && cbtStore.entries.isEmpty)
                    
                    Button("Import All Data") {
                        showingImportView = true
                    }
                    
                    Button("Delete All CBT Entries") {
                        showDeleteCBTAlert = true
                    }
                    .foregroundColor(.red)
                    .disabled(cbtStore.entries.isEmpty)
                }
                
                Section("Statistics") {
                    HStack {
                        Text("Total Notes")
                        Spacer()
                        Text("\(store.notes.count)")
                            .foregroundColor(AppColors.secondaryText)
                    }
                    
                    HStack {
                        Text("Total People")
                        Spacer()
                        Text("\(store.people.count)")
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
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingImportView) {
                ImportNotesView()
                    .environmentObject(store)
                    .environmentObject(cbtStore)
            }
            .alert("Copied", isPresented: $showCopyAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(copyAlertMessage)
            }
            .alert("Import/Export", isPresented: $store.showImportExportAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(store.importExportMessage)
            }
            .alert("Delete All CBT Entries?", isPresented: $showDeleteCBTAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete All", role: .destructive) {
                    cbtStore.deleteAllEntries()
                }
            } message: {
                Text("This will permanently delete all \(cbtStore.entries.count) CBT entries. This action cannot be undone.")
            }
            .alert("Import Status", isPresented: $showImportAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(importAlertMessage)
            }
        }
    }
    
    // MARK: - Export/Import Functions
    
    private func exportAllData() {
        let completeData = CompleteAppData(
            entries: store.notes,
            people: store.people,
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
        
        let totalItems = store.notes.count + store.people.count + cbtStore.entries.count
        copyAlertMessage = "Exported \(totalItems) items (\(store.notes.count) entries, \(store.people.count) people, \(cbtStore.entries.count) CBT) to clipboard"
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
        .environmentObject(NotesStore())
        .environmentObject(CBTStore())
} 