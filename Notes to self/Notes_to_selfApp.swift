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
    @StateObject private var remindersStore = RemindersStore()
    @StateObject private var peopleStore = PeopleStore()
    @StateObject private var cbtStore = CBTStore()
    @StateObject private var todoStore = TodoStore()
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(remindersStore)
                .environmentObject(peopleStore)
                .environmentObject(cbtStore)
                .environmentObject(todoStore)
                .onAppear {
                    print("📱 App appeared - RemindersStore and PeopleStore created")
                    remindersStore.refreshNotificationQueue()
                }
                .alert("Enable Notifications", isPresented: $remindersStore.showNotificationAlert) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("To get reminders, please enable notifications in Settings.")
                }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                remindersStore.refreshNotificationQueue()
            }
        }
    }
}





