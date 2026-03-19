//
//  RepTrackDesign.swift
//  RepTrack
//
//  Design system: spacing, corners, shadows, reusable card styles.
//

import SwiftUI

enum RepTrackDesign {
    static let cornerRadius: CGFloat = 16
    static let cornerRadiusSmall: CGFloat = 12
    static let cardShadowRadius: CGFloat = 8
    static let cardShadowY: CGFloat = 4
    static let cardShadowOpacity: Double = 0.08
}

struct CardStyleModifier: ViewModifier {
    var cornerRadius: CGFloat = RepTrackDesign.cornerRadius
    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color(.separator).opacity(0.3), lineWidth: 0.5)
            }
            .shadow(
                color: .black.opacity(RepTrackDesign.cardShadowOpacity),
                radius: RepTrackDesign.cardShadowRadius,
                x: 0,
                y: RepTrackDesign.cardShadowY
            )
    }
}

extension View {
    func repTrackCard(cornerRadius: CGFloat = RepTrackDesign.cornerRadius) -> some View {
        modifier(CardStyleModifier(cornerRadius: cornerRadius))
    }
}
