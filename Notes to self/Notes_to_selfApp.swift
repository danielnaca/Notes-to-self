//
//  Notes_to_selfApp.swift
//  Notes to self
//
//  Created by Daniel Nacamuli on 6/14/25.
//

import SwiftUI
import UserNotifications

// 📗 Main App: Root application structure
@main
struct Notes_to_selfApp: App {
    @StateObject private var store = NotesStore()
    @StateObject private var cbtStore = CBTStore()
    @StateObject private var todoStore = TodoStore()
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(cbtStore)
                .environmentObject(todoStore)
                .onAppear {
                    print("📱 App appeared - NotesStore created")
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





