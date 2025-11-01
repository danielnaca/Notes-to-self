//
//  TodoStore.swift
//  Notes to self
//
//  Created by AI Assistant
//

import Foundation
import SwiftUI
import CloudKit

class TodoStore: ObservableObject {
    @Published var todos: [TodoItem] = [] {
        didSet { save() }
    }
    
    private let appGroupID = "group.co.uk.cursive.NotesToSelf"
    private let todosKey = "developerTodos"
    private let cloudKit = CloudKitManager.shared
    private var isSyncing = false
    
    init() {
        loadFromCloudKit()
    }
    
    func addTodo(_ todo: TodoItem) {
        todos.insert(todo, at: 0)
    }
    
    func updateTodo(_ todo: TodoItem) {
        if let index = todos.firstIndex(where: { $0.id == todo.id }) {
            todos[index] = todo
        }
    }
    
    func deleteTodo(_ todo: TodoItem) {
        todos.removeAll(where: { $0.id == todo.id })
    }
    
    func toggleCompletion(_ todo: TodoItem) {
        if let index = todos.firstIndex(where: { $0.id == todo.id }) {
            todos[index].isCompleted.toggle()
        }
    }
    
    // MARK: - CloudKit Sync Methods
    private func loadFromCloudKit() {
        Task {
            do {
                guard await cloudKit.isCloudKitAvailable() else {
                    print("CloudKit not available, loading todos from UserDefaults fallback")
                    await MainActor.run { loadFromUserDefaults() }
                    return
                }
                let fetchedTodos = try await cloudKit.fetchTodos()
                await MainActor.run {
                    isSyncing = true
                    self.todos = fetchedTodos
                    isSyncing = false
                    print("Loaded \(fetchedTodos.count) todos from CloudKit")
                }
            } catch {
                print("Error loading todos from CloudKit: \(error)")
                await MainActor.run { loadFromUserDefaults() }
            }
        }
    }
    
    private func save() {
        guard !isSyncing else { return }
        Task {
            do {
                guard await cloudKit.isCloudKitAvailable() else {
                    print("CloudKit not available, saving todos to UserDefaults fallback")
                    await MainActor.run { saveToUserDefaults() }
                    return
                }
                try await cloudKit.saveTodos(todos)
                print("Saved \(todos.count) todos to CloudKit")
            } catch {
                print("Error saving todos to CloudKit: \(error)")
                await MainActor.run { saveToUserDefaults() }
            }
        }
    }
    
    // MARK: - UserDefaults Fallback
    private func loadFromUserDefaults() {
        guard let ud = UserDefaults(suiteName: appGroupID) else { return }
        if let data = ud.data(forKey: todosKey),
           let decoded = try? JSONDecoder().decode([TodoItem].self, from: data) {
            todos = decoded
            print("Loaded \(todos.count) todos from UserDefaults")
        }
    }
    
    private func saveToUserDefaults() {
        guard let ud = UserDefaults(suiteName: appGroupID) else { return }
        if let data = try? JSONEncoder().encode(todos) {
            ud.set(data, forKey: todosKey)
        }
    }
}

