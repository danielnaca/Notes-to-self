//
//  ImportDataView.swift
//  Notes to self
//
//  Created by AI Assistant on 9/30/25.
//

import SwiftUI

// 📗 Import Data View: Paste-based JSON import interface
struct ImportDataView: View {
    @EnvironmentObject var remindersStore: RemindersStore
    @EnvironmentObject var peopleStore: PeopleStore
    @EnvironmentObject var cbtStore: CBTStore
    @Environment(\.dismiss) private var dismiss
    @State private var pastedJSON: String = ""
    @State private var isImporting = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showConfirmation = false
    @State private var validatedData: CompleteAppData?
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                // Instructions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Paste Your Data")
                        .font(.headline)
                        .foregroundColor(AppColors.noteText)
                    
                    Text("Copy and paste the JSON content from your exported data below:")
                        .font(.body)
                        .foregroundColor(AppColors.secondaryText)
                    
                    Text("⚠️ Warning: This will overwrite all existing data")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                    
                    Text("Make sure you've exported your current data first")
                        .font(.caption)
                        .foregroundColor(AppColors.tertiaryText)
                }
                .padding(.horizontal)
                .padding(.top)
                
                // JSON Input Area
                VStack(alignment: .leading, spacing: 8) {
                    Text("JSON Content:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.noteText)
                        .padding(.horizontal)
                    
                    TextEditor(text: $pastedJSON)
                        .font(.system(.body, design: .monospaced))
                        .padding(12)
                        .background(AppColors.inputBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppColors.textFieldBorder, lineWidth: 1)
                        )
                        .frame(minHeight: 200)
                        .padding(.horizontal)
                    
                    if pastedJSON.isEmpty {
                        Text("Paste your exported JSON content here...")
                            .font(.caption)
                            .foregroundColor(AppColors.placeholderText)
                            .padding(.horizontal)
                    }
                }
                
                Spacer()
                
                // Action Buttons
                HStack(spacing: 16) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(AppColors.secondaryText)
                    
                    Spacer()
                    
                    Button(action: importAllData) {
                        HStack {
                            if isImporting {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.white)
                            }
                            Text(isImporting ? "Importing..." : "Import Data")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(pastedJSON.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isImporting)
                    .tint(AppColors.accent)
                }
                .padding()
            }
            .background(AppColors.background)
            .navigationTitle("Import Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Import Status", isPresented: $showAlert) {
                Button("OK", role: .cancel) {
                    if alertMessage.contains("success") {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
            .alert("Confirm Import", isPresented: $showConfirmation) {
                Button("Cancel", role: .cancel) {
                    validatedData = nil
                }
                Button("Import & Overwrite", role: .destructive) {
                    performImport()
                }
            } message: {
                if let data = validatedData {
                    Text("This will overwrite all existing data with:\n\n\(data.reminders.count) reminders\n\(data.people.count) people\n\(data.cbtEntries.count) CBT entries\n\nExported on: \(formatDate(data.exportDate))")
                }
            }
        }
    }
    
    private func importAllData() {
        isImporting = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let trimmedJSON = pastedJSON.trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard !trimmedJSON.isEmpty else {
                isImporting = false
                return
            }
            
            guard let data = trimmedJSON.data(using: .utf8) else {
                alertMessage = "Invalid text format. Please ensure you've pasted valid JSON content."
                showAlert = true
                isImporting = false
                return
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            do {
                // Step 1: Validate the JSON by attempting to decode it
                let completeData = try decoder.decode(CompleteAppData.self, from: data)
                
                // Step 2: JSON is valid, store it and show confirmation
                validatedData = completeData
                isImporting = false
                showConfirmation = true
                
            } catch {
                // Step 3: JSON is invalid, show error (no data touched)
                alertMessage = "Invalid data format: \(error.localizedDescription)\n\nPlease ensure you've copied the complete export from Settings."
                showAlert = true
                isImporting = false
                validatedData = nil
            }
        }
    }
    
    private func performImport() {
        guard let completeData = validatedData else { return }
        
        // Now we actually overwrite the data (only after user confirms)
        remindersStore.reminders = completeData.reminders
        peopleStore.people = completeData.people
        cbtStore.entries = completeData.cbtEntries
        
        let totalItems = completeData.reminders.count + completeData.people.count + completeData.cbtEntries.count
        alertMessage = "Successfully imported \(totalItems) items:\n• \(completeData.reminders.count) reminders\n• \(completeData.people.count) people\n• \(completeData.cbtEntries.count) CBT entries"
        showAlert = true
        validatedData = nil
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    ImportDataView()
        .environmentObject(RemindersStore())
        .environmentObject(PeopleStore())
        .environmentObject(CBTStore())
}

