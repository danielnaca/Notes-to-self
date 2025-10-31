//
//  SettingsView.swift
//  Notes to self
//
//  Created by Daniel Nacamuli on 6/15/25.
//

import SwiftUI

// 📗 Settings Screen: Configuration screen for app preferences
struct SettingsView: View {
    @EnvironmentObject var store: NotesStore
    @Environment(\.dismiss) private var dismiss
    @State private var notificationsPerWeek: Double = 2
    @State private var notificationsEnabled: Bool = true
    @State private var showingImportView = false
    @State private var showCopyAlert = false
    @State private var copyAlertMessage = ""
    
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
                
                Section("Copy Data") {
                    Button("Entries Data") {
                        copyEntriesToClipboard()
                    }
                    .disabled(store.notes.isEmpty)
                    
                    Button("People Data") {
                        copyPeopleToClipboard()
                    }
                    .disabled(store.people.isEmpty)
                }
                
                Section("Data Management") {
                    Button("Import Notes") {
                        showingImportView = true
                    }
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
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingImportView) {
                ImportNotesView()
                    .environmentObject(store)
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
        }
    }
    
    // MARK: - Copy Functions
    
    private func copyEntriesToClipboard() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        guard let data = try? encoder.encode(store.notes),
              let jsonString = String(data: data, encoding: .utf8) else {
            copyAlertMessage = "Failed to copy entries data"
            showCopyAlert = true
            return
        }
        
        UIPasteboard.general.string = jsonString
        copyAlertMessage = "Copied \(store.notes.count) entries to clipboard"
        showCopyAlert = true
    }
    
    private func copyPeopleToClipboard() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        guard let data = try? encoder.encode(store.people),
              let jsonString = String(data: data, encoding: .utf8) else {
            copyAlertMessage = "Failed to copy people data"
            showCopyAlert = true
            return
        }
        
        UIPasteboard.general.string = jsonString
        copyAlertMessage = "Copied \(store.people.count) people to clipboard"
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
} 