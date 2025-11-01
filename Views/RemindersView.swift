//
//  RemindersView.swift
//  Notes to self
//
//  Created by AI Assistant on 9/30/25.
//

import SwiftUI

// 📗 Reminders View: Messages-style interface for quick reminders
struct RemindersView: View {
    @EnvironmentObject var store: RemindersStore
    @State private var newReminderText: String = ""
    @State private var keyboardHeight: CGFloat = 0
    @FocusState private var isInputFocused: Bool
    @State private var editingReminderId: UUID? = nil
    @State private var scrollProxy: ScrollViewProxy? = nil
    
    private var isEditMode: Bool {
        editingReminderId != nil
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Messages area
                ScrollViewReader { proxy in
                    ScrollView {
                        Color.clear.frame(height: 0).onAppear {
                            scrollProxy = proxy
                        }
                        VStack(spacing: 12) {
                            if store.reminders.isEmpty {
                                // Empty state
                                VStack(spacing: 20) {
                                    Image(systemName: "bell")
                                        .font(.system(size: 64))
                                        .foregroundColor(AppColors.secondaryText)
                                    Text("No reminders yet")
                                        .font(.title2)
                                        .foregroundColor(AppColors.secondaryText)
                                    Text("Type a message below to create your first reminder")
                                        .font(.body)
                                        .foregroundColor(AppColors.tertiaryText)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 100)
                            } else {
                                // Show reminders in reverse order (newest at bottom)
                                ForEach(store.reminders.reversed()) { reminder in
                                    ReminderMessageBubble(reminder: reminder, isEditing: isEditMode && editingReminderId == reminder.id)
                                        .id(reminder.id)
                                        .opacity(isEditMode && editingReminderId != reminder.id ? 0 : 1.0)
                                        .onTapGesture {
                                            // Only allow editing when keyboard is closed
                                            if !isInputFocused {
                                                startEditing(reminder: reminder)
                                            }
                                        }
                                }
                            }
                        }
                        .padding()
                    }
                    .background(AppColors.background)
                    .disabled(isEditMode)
                    .contentShape(Rectangle())
                    .simultaneousGesture(
                        TapGesture().onEnded { _ in
                            // Dismiss keyboard and cancel edit when tapping messages area
                            if isEditMode {
                                cancelEditing()
                            } else {
                                isInputFocused = false
                            }
                        }
                    )
                    .onChange(of: store.reminders.count) { _, _ in
                        // Scroll to bottom when new reminder is added
                        if let lastReminder = store.reminders.first {
                            withAnimation {
                                proxy.scrollTo(lastReminder.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Input Bar - fixed at bottom, moves with keyboard
                VStack(spacing: 0) {
                    ZStack(alignment: .bottomTrailing) {
                        TextField("New reminder...", text: $newReminderText, axis: .vertical)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .padding(.trailing, 40) // Space for button
                            .background(AppColors.inputBackground)
                            .cornerRadius(20)
                            .focused($isInputFocused)
                            .lineLimit(1...5)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Button(action: sendReminder) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(newReminderText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? AppColors.tertiaryText : AppColors.accent)
                        }
                        .disabled(newReminderText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .padding(.trailing, 8)
                        .padding(.bottom, 6)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(AppColors.background)
                .padding(.bottom, keyboardHeight)
            }
            .ignoresSafeArea(.keyboard)
            .navigationTitle("Reminders")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                setupKeyboardObservers()
            }
        }
    }
    
    private func sendReminder() {
        let trimmed = newReminderText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        if let editingId = editingReminderId {
            // Update existing reminder
            if let index = store.reminders.firstIndex(where: { $0.id == editingId }) {
                let originalReminder = store.reminders[index]
                let updatedReminder = ReminderEntry(
                    id: originalReminder.id,
                    text: trimmed,
                    date: originalReminder.date,
                    lastModified: Date()
                )
                store.reminders[index] = updatedReminder
            }
            editingReminderId = nil
        } else {
            // Create new reminder
            let newReminder = ReminderEntry(text: trimmed)
            store.reminders.insert(newReminder, at: 0) // Store keeps newest first
        }
        
        newReminderText = ""
        isInputFocused = false // Dismiss keyboard
    }
    
    private func startEditing(reminder: ReminderEntry) {
        editingReminderId = reminder.id
        newReminderText = reminder.text
        isInputFocused = true
        
        // Scroll the editing message to the top
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation {
                scrollProxy?.scrollTo(reminder.id, anchor: .top)
            }
        }
    }
    
    private func cancelEditing() {
        editingReminderId = nil
        newReminderText = ""
        isInputFocused = false
    }
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                withAnimation {
                    // Position Input Bar 80px lower for proper spacing
                    keyboardHeight = keyboardFrame.height - 80
                }
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { _ in
            withAnimation {
                keyboardHeight = 0
            }
        }
    }
}

// 📗 Reminder Message Bubble: Individual reminder in chat style
struct ReminderMessageBubble: View {
    let reminder: ReminderEntry
    let isEditing: Bool
    
    var body: some View {
        HStack {
            Text(reminder.text)
                .font(.body)
                .foregroundColor(AppColors.noteText)
            Spacer()
        }
        .padding(12)
        .background(isEditing ? Color.clear : AppColors.inputBackground)
        .cornerRadius(16)
    }
}

#Preview {
    RemindersView()
        .environmentObject(RemindersStore())
}

