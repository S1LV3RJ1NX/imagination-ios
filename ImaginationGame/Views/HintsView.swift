//
//  HintsView.swift
//  ImaginationGame
//
//  Displays available hints for the current game session
//

import SwiftUI

struct HintData: Codable, Identifiable {
    let turn: Int
    let text: String
    
    var id: Int { turn }
}

struct HintsResponse: Codable {
    let hintsUnlocked: [Int]
    let hintsViewed: [Int]
    let hints: [String: HintData]
    
    enum CodingKeys: String, CodingKey {
        case hintsUnlocked = "hints_unlocked"
        case hintsViewed = "hints_viewed"
        case hints
    }
}

struct HintsView: View {
    let sessionId: String
    @State private var hints: [HintData] = []
    @State private var isLoading: Bool = true
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if isLoading {
                    ProgressView("Loading hints...")
                        .foregroundColor(.terminalGreen)
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.yellow)
                        
                        Text("Error")
                            .font(.system(size: 20, weight: .bold, design: .monospaced))
                            .foregroundColor(.terminalGreen)
                        
                        Text(error)
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundColor(.terminalGreen.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                } else if hints.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "lightbulb.slash")
                            .font(.system(size: 48))
                            .foregroundColor(.yellow)
                        
                        Text("No Hints Available")
                            .font(.system(size: 20, weight: .bold, design: .monospaced))
                            .foregroundColor(.terminalGreen)
                        
                        Text("Keep playing to unlock hints!")
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundColor(.terminalGreen.opacity(0.8))
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            ForEach(hints.sorted(by: { $0.turn < $1.turn })) { hint in
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "lightbulb.fill")
                                            .foregroundColor(.yellow)
                                        
                                        Text("Hint #\(hint.turn)")
                                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                                            .foregroundColor(.terminalGreen)
                                        
                                        Spacer()
                                    }
                                    
                                    Text(hint.text)
                                        .font(.system(size: 14, design: .monospaced))
                                        .foregroundColor(.terminalGreen.opacity(0.9))
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.terminalDarkGray.opacity(0.3))
                                        .cornerRadius(8)
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("💡 Available Hints")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.terminalGreen)
                }
            }
            .toolbarBackground(Color.terminalDarkGray, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .onAppear {
            loadHints()
        }
    }
    
    private func loadHints() {
        guard !sessionId.isEmpty else {
            errorMessage = "Invalid session"
            isLoading = false
            return
        }
        
        // Use APIService baseURL
        let baseURL = APIService.shared.apiBaseURL
        guard let url = URL(string: "\(baseURL)/game/hints/\(sessionId)") else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }
        
        print("🔍 Fetching hints from: \(url.absoluteString)")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    errorMessage = "Network error: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    errorMessage = "No data received"
                    return
                }
                
                // Debug: Print raw JSON
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📥 Hints JSON: \(jsonString)")
                }
                
                do {
                    let hintsResponse = try JSONDecoder().decode(HintsResponse.self, from: data)
                    print("✅ Decoded \(hintsResponse.hints.count) hints")
                    hints = Array(hintsResponse.hints.values)
                } catch {
                    errorMessage = "Failed to decode hints: \(error.localizedDescription)"
                    print("❌ Decode error: \(error)")
                    
                    // Try to decode as generic JSON for debugging
                    if let json = try? JSONSerialization.jsonObject(with: data) {
                        print("📋 Raw JSON structure: \(json)")
                    }
                }
            }
        }.resume()
    }
}

// MARK: - Preview

struct HintsView_Previews: PreviewProvider {
    static var previews: some View {
        HintsView(sessionId: "test-session-id")
    }
}
