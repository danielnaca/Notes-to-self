//
//  ImportNotesView.swift
//  Notes to self
//
//  Created by AI Assistant on 9/30/25.
//

import SwiftUI

// 📗 Import Notes View: Paste-based JSON import interface
struct ImportNotesView: View {
    @EnvironmentObject var store: NotesStore
    @Environment(\.dismiss) private var dismiss
    @State private var pastedJSON: String = ""
    @State private var isImporting = false
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                // Instructions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Paste Your Notes JSON")
                        .font(.headline)
                        .foregroundColor(AppColors.noteText)
                    
                    Text("Copy and paste the JSON content from your exported notes file below:")
                        .font(.body)
                        .foregroundColor(AppColors.secondaryText)
                    
                    Text("• Export format from Notes to Self")
                        .font(.caption)
                        .foregroundColor(AppColors.tertiaryText)
                    Text("• Raw JSON text content")
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
                    
                    Button(action: importNotes) {
                        HStack {
                            if isImporting {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.white)
                            }
                            Text(isImporting ? "Importing..." : "Import Notes")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(pastedJSON.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isImporting)
                    .tint(AppColors.accent)
                }
                .padding()
            }
            .background(AppColors.background)
            .navigationTitle("Import Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func importNotes() {
        isImporting = true
        
        // Add a small delay to show the loading state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let trimmedJSON = pastedJSON.trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard !trimmedJSON.isEmpty else {
                isImporting = false
                return
            }
            
            guard let data = trimmedJSON.data(using: .utf8) else {
                store.importExportMessage = "Invalid text format. Please ensure you've pasted valid JSON content."
                store.showImportExportAlert = true
                isImporting = false
                return
            }
            
            // Use the existing import function
            store.importNotes(from: data)
            isImporting = false
            
            // Close the import view after successful import
            if !store.showImportExportAlert || store.importExportMessage.contains("completed successfully") {
                dismiss()
            }
        }
    }
}

#Preview {
    ImportNotesView()
        .environmentObject(NotesStore())
}

