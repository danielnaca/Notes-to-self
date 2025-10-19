//
//  AlarmsView.swift
//  Notes to self
//
//  Created by AI Assistant on 9/30/25.
//

import SwiftUI

// 📗 Alarms View: Notification and reminder management
struct AlarmsView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "alarm")
                    .font(.system(size: 64))
                    .foregroundColor(AppColors.secondaryText)
                
                Text("Alarms")
                    .font(.title)
                    .foregroundColor(AppColors.noteText)
                
                Text("Coming soon...")
                    .font(.body)
                    .foregroundColor(AppColors.secondaryText)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColors.background)
            .navigationTitle("Alarms")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    AlarmsView()
}

