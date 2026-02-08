//
//  ProfileImageGenerator.swift
//  ImaginationGame
//
//  Generates shareable profile images with archetype and traits
//  Beautiful card design for social sharing
//

import UIKit
import SwiftUI

class ProfileImageGenerator {
    
    static let shared = ProfileImageGenerator()
    
    private init() {}
    
    /// Generate a shareable profile image
    func generateProfileImage(
        archetypeName: String,
        archetypeDescription: String,
        topTraits: [(name: String, value: Double)],
        chambersCompleted: Int,
        totalTime: String
    ) -> UIImage? {
        // Image size (optimized for social media)
        let width: CGFloat = 1080
        let height: CGFloat = 1350
        let size = CGSize(width: width, height: height)
        
        // Create renderer
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            
            // Background gradient
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [
                    UIColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1.0).cgColor,
                    UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0).cgColor
                ] as CFArray,
                locations: [0.0, 1.0]
            )!
            
            context.cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: width/2, y: 0),
                end: CGPoint(x: width/2, y: height),
                options: []
            )
            
            // Border
            let borderRect = rect.insetBy(dx: 40, dy: 40)
            context.cgContext.setStrokeColor(UIColor(red: 0, green: 1, blue: 0, alpha: 1).cgColor)
            context.cgContext.setLineWidth(4)
            context.cgContext.addPath(UIBezierPath(roundedRect: borderRect, cornerRadius: 20).cgPath)
            context.cgContext.strokePath()
            
            // Title
            let titleText = "IMAGINATION"
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedSystemFont(ofSize: 48, weight: .bold),
                .foregroundColor: UIColor(red: 0, green: 1, blue: 0, alpha: 1)
            ]
            let titleSize = titleText.size(withAttributes: titleAttributes)
            let titleRect = CGRect(
                x: (width - titleSize.width) / 2,
                y: 80,
                width: titleSize.width,
                height: titleSize.height
            )
            titleText.draw(in: titleRect, withAttributes: titleAttributes)
            
            // Wizard emoji
            let wizardEmoji = "🧙"
            let emojiAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 100)
            ]
            let emojiSize = wizardEmoji.size(withAttributes: emojiAttributes)
            let emojiRect = CGRect(
                x: (width - emojiSize.width) / 2,
                y: 170,
                width: emojiSize.width,
                height: emojiSize.height
            )
            wizardEmoji.draw(in: emojiRect, withAttributes: emojiAttributes)
            
            // Archetype name
            let archetypeAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 52, weight: .bold),
                .foregroundColor: UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
            ]
            let maxWidth = width - 160
            let archetypeSize = archetypeName.boundingRect(
                with: CGSize(width: maxWidth, height: 200),
                options: .usesLineFragmentOrigin,
                attributes: archetypeAttributes,
                context: nil
            ).size
            let archetypeRect = CGRect(
                x: (width - archetypeSize.width) / 2,
                y: 300,
                width: archetypeSize.width,
                height: archetypeSize.height
            )
            archetypeName.draw(in: archetypeRect, withAttributes: archetypeAttributes)
            
            // Description
            let descAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24),
                .foregroundColor: UIColor.white.withAlphaComponent(0.9)
            ]
            let descMaxWidth = width - 160
            let descSize = archetypeDescription.boundingRect(
                with: CGSize(width: descMaxWidth, height: 300),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: descAttributes,
                context: nil
            ).size
            let descRect = CGRect(
                x: (width - descMaxWidth) / 2,
                y: archetypeRect.maxY + 30,
                width: descMaxWidth,
                height: descSize.height
            )
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            paragraphStyle.lineSpacing = 6
            var descAttributesWithStyle = descAttributes
            descAttributesWithStyle[.paragraphStyle] = paragraphStyle
            
            archetypeDescription.draw(in: descRect, withAttributes: descAttributesWithStyle)
            
            // Traits section
            let traitsY = descRect.maxY + 60
            
            // "Top Traits" label
            let traitsLabelText = "TOP TRAITS"
            let traitsLabelAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedSystemFont(ofSize: 28, weight: .bold),
                .foregroundColor: UIColor(red: 0, green: 1, blue: 0, alpha: 1)
            ]
            let traitsLabelSize = traitsLabelText.size(withAttributes: traitsLabelAttributes)
            let traitsLabelRect = CGRect(
                x: (width - traitsLabelSize.width) / 2,
                y: traitsY,
                width: traitsLabelSize.width,
                height: traitsLabelSize.height
            )
            traitsLabelText.draw(in: traitsLabelRect, withAttributes: traitsLabelAttributes)
            
            // Draw trait bars
            var currentY = traitsLabelRect.maxY + 30
            let barWidth: CGFloat = width - 200
            let barX: CGFloat = 100
            
            for trait in topTraits.prefix(5) {
                // Trait name and value
                let traitNameAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.monospacedSystemFont(ofSize: 22, weight: .regular),
                    .foregroundColor: UIColor.white
                ]
                trait.name.draw(
                    at: CGPoint(x: barX, y: currentY),
                    withAttributes: traitNameAttributes
                )
                
                let valueText = String(format: "%.0f", trait.value)
                let valueAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.monospacedSystemFont(ofSize: 22, weight: .bold),
                    .foregroundColor: UIColor(red: 0, green: 1, blue: 0, alpha: 1)
                ]
                let valueSize = valueText.size(withAttributes: valueAttributes)
                valueText.draw(
                    at: CGPoint(x: barX + barWidth - valueSize.width, y: currentY),
                    withAttributes: valueAttributes
                )
                
                currentY += 35
                
                // Bar background
                let barBackgroundRect = CGRect(x: barX, y: currentY, width: barWidth, height: 20)
                context.cgContext.setFillColor(UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1).cgColor)
                context.cgContext.addPath(UIBezierPath(roundedRect: barBackgroundRect, cornerRadius: 10).cgPath)
                context.cgContext.fillPath()
                
                // Bar fill (based on value)
                let fillWidth = barWidth * CGFloat(trait.value / 100.0)
                let barFillRect = CGRect(x: barX, y: currentY, width: fillWidth, height: 20)
                
                // Color based on value
                let barColor: UIColor
                if trait.value >= 75 {
                    barColor = UIColor(red: 0, green: 1, blue: 0, alpha: 1) // Green
                } else if trait.value >= 50 {
                    barColor = UIColor(red: 1, green: 0.84, blue: 0, alpha: 1) // Yellow
                } else {
                    barColor = UIColor(red: 1, green: 0.5, blue: 0, alpha: 1) // Orange
                }
                
                context.cgContext.setFillColor(barColor.cgColor)
                context.cgContext.addPath(UIBezierPath(roundedRect: barFillRect, cornerRadius: 10).cgPath)
                context.cgContext.fillPath()
                
                currentY += 40
            }
            
            // Stats footer
            currentY += 20
            let statsText = "🏆 \(chambersCompleted) Chambers  •  ⏱️ \(totalTime)"
            let statsAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedSystemFont(ofSize: 24, weight: .regular),
                .foregroundColor: UIColor.white.withAlphaComponent(0.7)
            ]
            let statsSize = statsText.size(withAttributes: statsAttributes)
            let statsRect = CGRect(
                x: (width - statsSize.width) / 2,
                y: currentY,
                width: statsSize.width,
                height: statsSize.height
            )
            statsText.draw(in: statsRect, withAttributes: statsAttributes)
            
            // Bottom branding
            let brandText = "imagination.game"
            let brandAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedSystemFont(ofSize: 20, weight: .regular),
                .foregroundColor: UIColor(red: 0, green: 1, blue: 0, alpha: 0.5)
            ]
            let brandSize = brandText.size(withAttributes: brandAttributes)
            let brandRect = CGRect(
                x: (width - brandSize.width) / 2,
                y: height - 80,
                width: brandSize.width,
                height: brandSize.height
            )
            brandText.draw(in: brandRect, withAttributes: brandAttributes)
        }
    }
    
    /// Generate image and return as data for sharing
    func generateProfileImageData(
        archetypeName: String,
        archetypeDescription: String,
        topTraits: [(name: String, value: Double)],
        chambersCompleted: Int,
        totalTime: String
    ) -> Data? {
        guard let image = generateProfileImage(
            archetypeName: archetypeName,
            archetypeDescription: archetypeDescription,
            topTraits: topTraits,
            chambersCompleted: chambersCompleted,
            totalTime: totalTime
        ) else {
            return nil
        }
        
        return image.pngData()
    }
}
