//
//  ForgeCardStyle.swift
//  RepTrack
//
//  Single reusable card style across the app.
//  Solid fill (no material), one radius, one border, one shadow recipe.
//

import SwiftUI

struct ForgeCardStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: RepTrackDesign.cornerRadius, style: .continuous)
                    .fill(ForgeTheme.cardLight)
            }
            .overlay {
                RoundedRectangle(cornerRadius: RepTrackDesign.cornerRadius, style: .continuous)
                    .stroke(ForgeTheme.cardLightBorder, lineWidth: 0.5)
            }
            // Apple-style restraint: keep cards flat, use border as depth.
    }
}

extension View {
    func forgeCard() -> some View {
        modifier(ForgeCardStyleModifier())
    }
}

