//
//  DistortionPickerView.swift
//  Notes to self
//
//  Created by AI Assistant on 10/31/25.
//

import SwiftUI

// 📗 Distortion Picker View: Sheet for selecting multiple cognitive distortions
struct DistortionPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedIds: [UUID]
    
    var body: some View {
        NavigationView {
            List(CognitiveDistortion.allDistortions) { distortion in
                Button(action: {
                    toggleSelection(distortion)
                }) {
                    HStack(spacing: 12) {
                        Text(distortion.emoji)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(distortion.title)
                                .font(.headline)
                                .foregroundColor(AppColors.noteText)
                            
                            Text(distortion.description)
                                .font(.caption)
                                .foregroundColor(AppColors.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        Spacer()
                        
                        if selectedIds.contains(distortion.id) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(AppColors.accent)
                        } else {
                            Image(systemName: "circle")
                                .foregroundColor(AppColors.tertiaryText)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .listStyle(PlainListStyle())
            .navigationTitle("Select Distortions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.accent)
                }
            }
        }
    }
    
    private func toggleSelection(_ distortion: CognitiveDistortion) {
        if let index = selectedIds.firstIndex(of: distortion.id) {
            selectedIds.remove(at: index)
        } else {
            selectedIds.append(distortion.id)
        }
    }
}

#Preview {
    DistortionPickerView(selectedIds: .constant([]))
}

