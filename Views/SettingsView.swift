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
    @State private var showingShareSheet = false
    @State private var exportURL: URL?
    
    var body: some View {
        NavigationView {
            Form {
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
                    Button("Export Notes") {
                        if let url = store.exportNotes() {
                            exportURL = url
                            showingShareSheet = true
                        }
                    }
                    .disabled(store.notes.isEmpty)
                    
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
            .sheet(isPresented: $showingShareSheet) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }
            .alert("Import/Export", isPresented: $store.showImportExportAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(store.importExportMessage)
            }
        }
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