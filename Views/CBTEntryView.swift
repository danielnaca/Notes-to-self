//
//  CBTEntryView.swift
//  Notes to self
//
//  Created by AI Assistant on 10/31/25.
//

import SwiftUI

// 📗 CBT Entry View: Create/view/edit CBT entries with autosave
struct CBTEntryView: View {
    @EnvironmentObject var store: CBTStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var entry: CBTEntry
    @State private var showingDistortionPicker = false
    
    init(entry: CBTEntry) {
        _entry = State(initialValue: entry)
    }
    
    var selectedDistortions: [CognitiveDistortion] {
        entry.distortionIds.compactMap { id in
            CognitiveDistortion.allDistortions.first(where: { $0.id == id })
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 1. Situation
                VStack(alignment: .leading, spacing: 8) {
                    Text("Situation")
                        .font(.headline)
                        .foregroundColor(AppColors.noteText)
                    
                    TextField("What happened? How did you feel?", text: $entry.situation, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(1...10)
                        .onChange(of: entry.situation) { _, _ in
                            autosave()
                        }
                }
                
                // 2. Distortions
                VStack(alignment: .leading, spacing: 8) {
                    Text("Cognitive Distortions")
                        .font(.headline)
                        .foregroundColor(AppColors.noteText)
                    
                    HStack(spacing: 8) {
                        ForEach(selectedDistortions) { distortion in
                            Button(action: { showingDistortionPicker = true }) {
                                Text(distortion.emoji)
                                    .font(.title2)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        Button(action: { showingDistortionPicker = true }) {
                            Image(systemName: "plus.circle")
                                .font(.title2)
                                .foregroundColor(AppColors.accent)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                // 3. Challenge
                VStack(alignment: .leading, spacing: 8) {
                    Text("Challenge the Thought")
                        .font(.headline)
                        .foregroundColor(AppColors.noteText)
                    
                    TextField("What evidence contradicts this thought?", text: $entry.challenge, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(1...10)
                        .onChange(of: entry.challenge) { _, _ in
                            autosave()
                        }
                }
                
                // 4. Alternative
                VStack(alignment: .leading, spacing: 8) {
                    Text("Alternative Thought")
                        .font(.headline)
                        .foregroundColor(AppColors.noteText)
                    
                    TextField("What's a more balanced perspective?", text: $entry.alternative, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(1...10)
                        .onChange(of: entry.alternative) { _, _ in
                            autosave()
                        }
                }
                
                // 5. Notes
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(.headline)
                        .foregroundColor(AppColors.noteText)
                    
                    TextField("Additional observations...", text: $entry.notes, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(1...10)
                        .onChange(of: entry.notes) { _, _ in
                            autosave()
                        }
                }
                
                // Delete button (only show for existing entries)
                if store.entries.contains(where: { $0.id == entry.id }) {
                    Button(action: deleteEntry) {
                        HStack {
                            Spacer()
                            Text("Delete Entry")
                                .foregroundColor(.red)
                            Spacer()
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                    }
                    .padding(.top, 16)
                }
            }
            .padding()
        }
        .background(AppColors.background)
        .navigationTitle("CBT Entry")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingDistortionPicker) {
            DistortionPickerView(selectedIds: $entry.distortionIds)
                .onDisappear {
                    autosave()
                }
        }
    }
    
    private func autosave() {
        store.updateEntry(entry)
    }
    
    private func deleteEntry() {
        store.deleteEntry(entry)
        dismiss()
    }
}

// 📗 Flow Layout: Wraps content horizontally (for distortion chips)
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX, y: bounds.minY + result.frames[index].minY), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var frames: [CGRect] = []
        var size: CGSize = .zero
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

#Preview {
    NavigationView {
        CBTEntryView(entry: CBTEntry())
            .environmentObject(CBTStore())
    }
}

