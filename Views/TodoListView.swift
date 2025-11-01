//
//  TodoListView.swift
//  Notes to self
//
//  Created by AI Assistant
//

import SwiftUI

struct TodoListView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var todoStore: TodoStore
    @State private var newTodoText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Input area at top
                HStack {
                    TextField("New todo...", text: $newTodoText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            addTodo()
                        }
                    
                    Button(action: addTodo) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(AppColors.accent)
                    }
                    .disabled(newTodoText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
                .background(Color.white)
                
                // Todo list
                if todoStore.todos.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Text("No todos yet")
                            .font(.headline)
                            .foregroundColor(AppColors.secondaryText)
                        Text("Add one above to get started")
                            .font(.subheadline)
                            .foregroundColor(AppColors.tertiaryText)
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(todoStore.todos) { todo in
                            HStack(spacing: 12) {
                                Button(action: {
                                    todoStore.toggleCompletion(todo)
                                }) {
                                    Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .font(.title3)
                                        .foregroundColor(todo.isCompleted ? AppColors.accent : AppColors.tertiaryText)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Text(todo.text)
                                    .foregroundColor(todo.isCompleted ? AppColors.tertiaryText : AppColors.noteText)
                                    .strikethrough(todo.isCompleted)
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete { indexSet in
                            indexSet.forEach { index in
                                let todo = todoStore.todos[index]
                                todoStore.deleteTodo(todo)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .background(AppColors.background)
            .navigationTitle("Developer Todos")
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
    
    private func addTodo() {
        let trimmedText = newTodoText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        let todo = TodoItem(text: trimmedText)
        todoStore.addTodo(todo)
        newTodoText = ""
    }
}

#Preview {
    TodoListView()
        .environmentObject(TodoStore())
}

