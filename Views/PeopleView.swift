//
//  PeopleView.swift
//  Notes to self
//
//  Created by AI Assistant on 9/30/25.
//

import SwiftUI

// 📗 People View: People-related functionality
struct PeopleView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "person.2")
                    .font(.system(size: 64))
                    .foregroundColor(AppColors.secondaryText)
                
                Text("People")
                    .font(.title)
                    .foregroundColor(AppColors.noteText)
                
                Text("Coming soon...")
                    .font(.body)
                    .foregroundColor(AppColors.secondaryText)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColors.background)
            .navigationTitle("People")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    PeopleView()
}

