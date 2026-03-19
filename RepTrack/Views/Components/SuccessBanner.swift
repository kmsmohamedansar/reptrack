//
//  SuccessBanner.swift
//  RepTrack
//

import SwiftUI

struct SuccessBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: ForgeTheme.spaceS) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(ForgeTheme.gold)

            Text(message)
                .font(.caption.weight(.semibold))
                .foregroundStyle(ForgeTheme.primaryText)
                .lineLimit(2)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, ForgeTheme.spaceM)
        .padding(.vertical, ForgeTheme.spaceS)
        .background(
            RoundedRectangle(cornerRadius: RepTrackDesign.cornerRadiusSmall, style: .continuous)
                .fill(ForgeTheme.cardLight)
        )
        .overlay(
            RoundedRectangle(cornerRadius: RepTrackDesign.cornerRadiusSmall, style: .continuous)
                .stroke(ForgeTheme.cardLightBorder, lineWidth: 0.5)
        )
    }
}

extension View {
    func successBanner(message: Binding<String?>, autoDismissAfter: TimeInterval = 1.2) -> some View {
        overlay(alignment: .top) {
            if let text = message.wrappedValue {
                SuccessBanner(message: text)
                    .padding(.horizontal, ForgeTheme.gutter)
                    .padding(.top, ForgeTheme.spaceM)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.easeInOut(duration: ForgeTheme.quick), value: message.wrappedValue)
                    .task(id: text) {
                        do {
                            try await Task.sleep(nanoseconds: UInt64(autoDismissAfter * 1_000_000_000))
                        } catch {
                            return
                        }
                        if message.wrappedValue == text {
                            message.wrappedValue = nil
                        }
                    }
            }
        }
    }
}

