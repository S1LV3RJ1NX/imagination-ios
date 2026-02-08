//
//  ProfileTabContent.swift
//  ImaginationGame
//
//  Profile tab showing journey progress
//

import SwiftUI

struct ProfileTabContent: View {
    let sessionId: String?
    let chambersCompleted: Int
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.circle")
                .font(.system(size: 64))
                .foregroundColor(.terminalGreen)
            
            Text("YOUR PROFILE")
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundColor(.terminalGreen)
            
            if sessionId != nil {
                Text("Journey in Progress")
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(.gray)
                
                Text("Chambers Completed: \(chambersCompleted)")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.terminalGreen)
                
                VStack(spacing: 4) {
                    Text("Complete all 20 chambers")
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(.cyan)
                    
                    Text("to unlock your personality archetype")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.cyan.opacity(0.8))
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.cyan.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                        )
                )
                .padding(.horizontal)
            } else {
                Text("No Active Journey")
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(.gray)
                
                Text("Start a chamber to begin tracking your personality")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.gray.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}
