//
//  ForgeTheme.swift
//  RepTrack
//
//  Northstar Forge brand: light theme with antique gold accent.
//

import SwiftUI

enum ForgeTheme {
    // MARK: - Accent (unchanged)
    static let gold     = Color(red: 212/255, green: 175/255, blue: 55/255)  // #D4AF37
    static let goldLight = Color(red: 230/255, green: 195/255, blue: 95/255)
    static let glowBlue = Color(red: 100/255, green: 160/255, blue: 220/255).opacity(0.4)

    // MARK: - Light theme
    static let backgroundLight = Color(red: 248/255, green: 246/255, blue: 242/255)  // warm off-white
    static let backgroundLightBottom = Color(red: 238/255, green: 235/255, blue: 228/255)
    static let cardLight = Color(red: 255/255, green: 254/255, blue: 252/255)
    static let cardLightBorder = Color(red: 220/255, green: 210/255, blue: 190/255).opacity(0.5)
    static let primaryText = Color(red: 45/255, green: 42/255, blue: 38/255)
    static let secondaryText = Color(red: 45/255, green: 42/255, blue: 38/255).opacity(0.75)
    static let tertiaryText = Color(red: 45/255, green: 42/255, blue: 38/255).opacity(0.55)
    static let ringTrackLight = Color(red: 230/255, green: 225/255, blue: 215/255)
    /// For FAB icon on gold button
    static let buttonIconDark = Color(red: 55/255, green: 48/255, blue: 35/255)

    // MARK: - App icon & splash (Northstar Forge brand)
    /// Deep navy for icon/splash background #0B1A2A
    static let iconNavy = Color(red: 11/255, green: 26/255, blue: 42/255)
    static let navySplashBottom = Color(red: 8/255, green: 20/255, blue: 35/255)
    /// Full-screen gradient for splash (deep navy edge-to-edge)
    static var splashNavyGradient: LinearGradient {
        LinearGradient(
            colors: [iconNavy, navySplashBottom],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    static let iconGold = Color(red: 212/255, green: 175/255, blue: 55/255)
    static let iconGoldLight = Color(red: 240/255, green: 210/255, blue: 120/255)
    static let iconGlow = Color(red: 255/255, green: 235/255, blue: 180/255)

    // MARK: - Legacy (for any remaining refs; map to light)
    static let navyDeep = buttonIconDark
    static let navyMid  = ringTrackLight

    // MARK: - Spacing (8-pt grid: 4 / 8 / 16 / 24 / 32)
    static let spaceXS: CGFloat = 4
    static let spaceS: CGFloat = 8
    static let spaceM: CGFloat = 16
    static let spaceL: CGFloat = 24
    static let spaceXL: CGFloat = 32

    /// Standard horizontal gutter used across screens (aligns everything).
    static let gutter: CGFloat = spaceM

    /// Standard internal padding used inside cards.
    static let cardPadding: CGFloat = spaceM

    /// Extra bottom padding to keep content clear of the floating action button.
    static let fabClearance: CGFloat = 96

    // MARK: - Motion tokens
    static let quick: Double = 0.2
    static let standard: Double = 0.3
    static var emphasisSpring: Animation {
        .spring(response: 0.35, dampingFraction: 0.8)
    }

    // MARK: - Background (light)
    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [backgroundLight, backgroundLightBottom],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Alias for consistency
    static var navyGradient: LinearGradient { backgroundGradient }

    // MARK: - Gold gradient (for buttons, accents)
    static var goldGradient: LinearGradient {
        LinearGradient(
            colors: [goldLight, gold],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
