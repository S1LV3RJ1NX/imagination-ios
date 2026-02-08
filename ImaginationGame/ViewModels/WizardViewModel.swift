//
//  WizardViewModel.swift
//  ImaginationGame
//
//  Manages archetype reveal and profile sharing
//

import Foundation
import Combine
import UIKit

@MainActor
class WizardViewModel: ObservableObject {
    
    // MARK: - Published State
    
    @Published var archetype: Archetype?
    @Published var traits: PlayerTraits?
    @Published var journeyStats: JourneyStats?
    @Published var completionMessage: String?
    @Published var isLoading = false
    @Published var error: String?
    @Published var shareImage: UIImage?
    @Published var isGeneratingShareImage = false
    
    // MARK: - Dependencies
    
    private let apiService: APIService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(apiService: APIService? = nil) {
        self.apiService = apiService ?? .shared
    }
    
    // MARK: - Public Methods
    
    /// Load wizard reveal (archetype + traits + stats)
    func loadWizardReveal(sessionId: String) {
        isLoading = true
        error = nil
        
        apiService.getWizardReveal(sessionId: sessionId)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.error = "Failed to load wizard reveal: \(error.localizedDescription)"
                        print("❌ Wizard reveal error: \(error)")
                    }
                },
                receiveValue: { [weak self] response in
                    self?.archetype = response.archetype
                    self?.traits = response.traits
                    self?.journeyStats = response.journeyStats
                    self?.completionMessage = response.completionMessage
                    print("🧙 Loaded archetype: \(response.archetype.name)")
                }
            )
            .store(in: &cancellables)
    }
    
    /// Generate shareable profile image locally
    func generateShareImage(sessionId: String) {
        guard let archetype = archetype,
              let stats = journeyStats else {
            error = "Profile data not loaded"
            return
        }
        
        isGeneratingShareImage = true
        error = nil
        
        // Capture values on main actor before background work
        let archetypeName = archetype.name
        let archetypeDescription = archetype.description
        let topTraits = self.topTraits
        let chambersCompleted = stats.chambersCompleted
        let totalTime = stats.formattedTotalTime
        
        // Generate image on background thread
        Task.detached { [weak self] in
            // Generate image (UIKit drawing, runs on background thread)
            let image = await ProfileImageGenerator.shared.generateProfileImage(
                archetypeName: archetypeName,
                archetypeDescription: archetypeDescription,
                topTraits: topTraits,
                chambersCompleted: chambersCompleted,
                totalTime: totalTime
            )
            
            // Return to main actor to update UI
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                self.isGeneratingShareImage = false
                if let image = image {
                    self.shareImage = image
                    print("🖼️ Generated share image: \(archetypeName)")
                    // Automatically trigger share sheet
                    self.shareProfile()
                } else {
                    self.error = "Failed to generate share image"
                }
            }
        }
    }
    
    /// Share profile using iOS Share Sheet
    func shareProfile() {
        guard let image = shareImage else {
            error = "No image to share"
            return
        }
        
        // Create share text
        let shareText = "I completed the Imagination journey and discovered I'm \(archetype?.name ?? "a unique archetype")! 🧙✨"
        
        let activityVC = UIActivityViewController(
            activityItems: [shareText, image],
            applicationActivities: nil
        )
        
        // Exclude some activity types
        activityVC.excludedActivityTypes = [
            .assignToContact,
            .addToReadingList,
            .openInIBooks
        ]
        
        // Get the root view controller to present from
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            
            // For iPad support
            if let popoverController = activityVC.popoverPresentationController {
                popoverController.sourceView = rootVC.view
                popoverController.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
                popoverController.permittedArrowDirections = []
            }
            
            rootVC.present(activityVC, animated: true)
        }
    }
    
    /// Get trait breakdown as array for UI display
    var traitBreakdown: [(name: String, value: Double)] {
        return traits?.allTraits ?? []
    }
    
    /// Get top 5 traits
    var topTraits: [(name: String, value: Double)] {
        return traits?.topTraits ?? []
    }
    
    /// Check if reveal is loaded
    var isRevealed: Bool {
        return archetype != nil && traits != nil
    }
    
    /// Clear all state (for new game)
    func reset() {
        archetype = nil
        traits = nil
        journeyStats = nil
        completionMessage = nil
        shareImage = nil
        error = nil
    }
}
