//
//  ForgeTypography.swift
//  RepTrack
//
//  Strict typography hierarchy:
//  - One hero (largeTitle)
//  - Subtle section headers
//  - Calm body text
//  - Numbers are the visual focus
//

import SwiftUI

enum ForgeTypography {
    static func hero(_ text: String) -> Text {
        Text(text)
            .font(.largeTitle.weight(.bold))
            .foregroundStyle(ForgeTheme.primaryText)
    }

    static func section(_ text: String) -> Text {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(ForgeTheme.secondaryText)
    }

    static func body(_ text: String) -> Text {
        Text(text)
            .font(.body)
            .foregroundStyle(ForgeTheme.secondaryText)
    }

    static func caption(_ text: String) -> Text {
        Text(text)
            .font(.caption)
            .foregroundStyle(ForgeTheme.tertiaryText)
    }

    static func statValue(_ text: String) -> Text {
        Text(text)
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .foregroundStyle(ForgeTheme.primaryText)
    }

    static func statLabel(_ text: String) -> Text {
        Text(text)
            .font(.caption2)
            .foregroundStyle(ForgeTheme.tertiaryText)
    }
}

