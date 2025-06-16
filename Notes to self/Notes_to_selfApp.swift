//
//  Notes_to_selfApp.swift
//  Notes to self
//
//  Created by Daniel Nacamuli on 6/14/25.
//

import SwiftUI
import UserNotifications

// MARK: - Shared Model
struct Note: Identifiable, Codable, Equatable {
    let id: UUID
    let text: String
    let date: Date
    
    init(id: UUID = UUID(), text: String, date: Date = Date()) {
        self.id = id
        self.text = text
        self.date = date
    }
}

class NotesStore: ObservableObject {
    @Published var notes: [Note] = [] {
        didSet { save() }
    }
    @Published var newNote: String = ""
    @Published var currentIndex: Int = 0 { didSet { save() } }
    @Published var showNotificationAlert = false
    
    private let appGroupID = "group.co.uk.cursive.NotesToSelf"
    private let notesKey = "notes"
    private let indexKey = "currentIndex"
    
    init() {
        load()
    }
    
    func addNote() {
        let trimmed = newNote.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        notes.insert(Note(text: trimmed), at: 0)
        newNote = ""
    }
    
    func delete(at offsets: IndexSet) {
        notes.remove(atOffsets: offsets)
        if currentIndex >= notes.count { currentIndex = 0 }
    }
    
    func refreshNotificationQueue() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                if settings.authorizationStatus == .notDetermined {
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                        DispatchQueue.main.async {
                            self.showNotificationAlert = !granted
                        }
                        if granted { self.scheduleNotifications() }
                    }
                } else if settings.authorizationStatus == .authorized {
                    self.scheduleNotifications()
                } else {
                    DispatchQueue.main.async {
                        self.showNotificationAlert = true
                    }
                }
            }
        }
    }
    
    private func scheduleNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        guard !notes.isEmpty else { return }
        let count = 10 // 10 notifications, 3 days apart = 30 days
        let calendar = Calendar.current
        let now = Date()
        for i in 0..<count {
            let content = UNMutableNotificationContent()
            guard let randomNote = notes.randomElement() else { continue }
            content.title = "Notes to Self"
            content.body = randomNote.text
            content.sound = .default
            if let fireDate = calendar.date(byAdding: .day, value: i * 3, to: now) {
                let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: fireDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
                let request = UNNotificationRequest(identifier: "note_\(i)", content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        print("Notification scheduling error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    private func save() {
        guard let ud = UserDefaults(suiteName: appGroupID) else { return }
        if let data = try? JSONEncoder().encode(notes) {
            ud.set(data, forKey: notesKey)
        }
        ud.set(currentIndex, forKey: indexKey)
    }
    
    private func load() {
        guard let ud = UserDefaults(suiteName: appGroupID) else { return }
        if let data = ud.data(forKey: notesKey), let decoded = try? JSONDecoder().decode([Note].self, from: data) {
            notes = decoded
        }
        currentIndex = ud.integer(forKey: indexKey)
    }
}

// MARK: - Main App
@main
struct Notes_to_selfApp: App {
    @StateObject private var store = NotesStore()
    @Environment(\.scenePhase) private var scenePhase
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .onAppear {
                    store.refreshNotificationQueue()
                }
                .alert("Enable Notifications", isPresented: $store.showNotificationAlert) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("To get reminders, please enable notifications in Settings.")
                }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                store.refreshNotificationQueue()
            }
        }
    }
}

struct ExpandingTextView: View {
    @Binding var text: String
    let maxHeight: CGFloat
    var onCommit: (() -> Void)? = nil
    var onSettingsPressed: (() -> Void)? = nil
    @FocusState private var isFocused: Bool
    @Binding var isExternallyFocused: Bool
    @Binding var textHeight: CGFloat
    @State private var dynamicHeight: CGFloat = AppDimensions.baseTextHeight
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text("Enter note...")
                        .foregroundColor(AppColors.placeholderText)
                        .padding(.horizontal, AppPadding.placeholderHorizontal)
                        .padding(.vertical, AppPadding.placeholderVertical)
                }
                
                TextEditor(text: $text)
                    .frame(height: dynamicHeight)
                    .focused($isFocused)
                    .padding(AppPadding.textFieldInner)
                    .cornerRadius(AppDimensions.textFieldCornerRadius)
                    .submitLabel(.done)
                    .onChange(of: isFocused) { _, newValue in
                        isExternallyFocused = newValue
                    }
                    .onChange(of: text) { oldValue, newValue in
                        // Check if return was pressed (newline added)
                        if newValue.hasSuffix("\n") && !oldValue.hasSuffix("\n") {
                            text = String(newValue.dropLast()) // Remove the newline
                            isFocused = false // Close keyboard
                            onCommit?()
                        }
                    }
                
                // Round black button - appears when not editing
                if !isFocused {
                    Button(action: {
                        onSettingsPressed?()
                    }) {
                        Circle()
                            .fill(AppColors.settingsButton)
                            .frame(width: AppDimensions.settingsButtonSize, height: AppDimensions.settingsButtonSize)
                    }
                    .position(x: geometry.size.width - AppPositioning.settingsButtonFromRight, y: AppPositioning.settingsButtonFromTop)
                }
                
                // Hidden text for height measurement
                Text(text + " ")
                    .font(AppTypography.bodyFont)
                    .frame(width: geometry.size.width - AppPositioning.hiddenTextWidthOffset, alignment: .leading)
                    .background(GeometryReader { geo in
                        Color.clear
                            .onAppear {
                                let newHeight = min(max(AppDimensions.baseTextHeight, geo.size.height), maxHeight)
                                dynamicHeight = newHeight
                                textHeight = newHeight
                            }
                            .onChange(of: text) { _, _ in
                                let newHeight = min(max(AppDimensions.baseTextHeight, geo.size.height), maxHeight)
                                dynamicHeight = newHeight
                                textHeight = newHeight
                            }
                    })
                    .hidden()
            }
        }
        .frame(minHeight: AppDimensions.baseTextHeight, maxHeight: maxHeight)
    }
}

struct ContentView: View {
    @EnvironmentObject var store: NotesStore
    @State private var isInputFocused: Bool = false
    @State private var textHeight: CGFloat = AppDimensions.baseTextHeight
    @State private var showSettings = false
    
    private let baseHeight: CGFloat = AppDimensions.baseTextHeight
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollViewReader { proxy in
                List {
                    ForEach(store.notes.reversed()) { note in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(note.text)
                                .foregroundColor(AppColors.noteText)
                        }
                        .listRowBackground(AppColors.listBackground)
                        .id(note.id)
                    }
                    .onDelete(perform: store.delete)
                }
                .scrollContentBackground(.hidden)
                .background(AppColors.listBackground)
                .padding(.bottom, AppPadding.listBottom)
                .simultaneousGesture(
                    TapGesture().onEnded {
                        isInputFocused = false
                    }
                )
                .onAppear {
                    // Scroll to the bottom (newest item) when app opens
                    if let lastNote = store.notes.first {
                        proxy.scrollTo(lastNote.id, anchor: .bottom)
                    }
                }
                .onChange(of: store.notes.count) { oldCount, newCount in
                    // Scroll to bottom when new note is added
                    if newCount > oldCount, let lastNote = store.notes.first {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(lastNote.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            HStack {
                ExpandingTextView(
                    text: $store.newNote,
                    maxHeight: AppDimensions.textInputMaxHeight,
                    onCommit: {
                        store.addNote()
                    },
                    onSettingsPressed: {
                        showSettings = true
                    },
                    isExternallyFocused: $isInputFocused,
                    textHeight: $textHeight
                )
                .padding(AppPadding.composerAllSides)
            }
            .background(AppColors.composerBackground)
            .padding(.horizontal)
            .padding(.bottom, 0)
            .offset(y: -(textHeight - baseHeight))
        }
        .background(AppColors.appBackground.ignoresSafeArea())
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(store)
        }
    }
}



