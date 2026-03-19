//
//  AppIconView.swift
//  RepTrack
//
//  Northstar Forge app icon: glowing north star, hammer + anvil, minimal alchemy ring.
//  Use with ImageRenderer to export 1024×1024 for AppIcon.appiconset.
//  Apple App Store rules: no text, centered, strong silhouette, minimal detail.
//

import SwiftUI

enum AppIconVariation {
    case standard   // North star above hammer + anvil (A)
    case hammerSpark // Hammer striking star spark (B)
    case starOnly   // Minimal north star emblem only (C)
}

struct AppIconView: View {
    var variation: AppIconVariation = .standard
    var size: CGFloat = 1024

    var body: some View {
        GeometryReader { geo in
            let r = min(geo.size.width, geo.size.height) / 2
            let cx = geo.size.width / 2
            let cy = geo.size.height / 2
            ZStack {
                // Background – deep navy with subtle inner shadow
                RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                    .fill(ForgeTheme.iconNavy)
                    .overlay(
                        RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                            .stroke(Color.black.opacity(0.3), lineWidth: max(1, size / 256))
                            .blur(radius: size / 128)
                    )

                switch variation {
                case .standard:
                    mainIconContent(cx: cx, cy: cy, r: r)
                case .hammerSpark:
                    hammerSparkContent(cx: cx, cy: cy, r: r)
                case .starOnly:
                    starOnlyContent(cx: cx, cy: cy, r: r)
                }
            }
        }
        .frame(width: size, height: size)
    }

    // MARK: - Variation A: North star above hammer + anvil
    private func mainIconContent(cx: CGFloat, cy: CGFloat, r: CGFloat) -> some View {
        ZStack {
            // Radial glow behind star
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            ForgeTheme.iconGlow.opacity(0.5),
                            ForgeTheme.iconGold.opacity(0.2),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: r * 0.5
                    )
                )
                .frame(width: r, height: r)
                .offset(y: -r * 0.22)
                .blur(radius: r * 0.08)

            // Minimal alchemy ring (double circle, no symbols)
            ForgeIconRing(radius: r * 0.72, lineWidth: max(2, r / 80))

            // North star (8-point, centered above)
            NorthStarShape()
                .fill(
                    LinearGradient(
                        colors: [ForgeTheme.iconGoldLight, ForgeTheme.iconGold],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    NorthStarShape()
                        .stroke(ForgeTheme.iconGoldLight.opacity(0.6), lineWidth: max(1, r / 120))
                )
                .frame(width: r * 0.5, height: r * 0.5)
                .offset(y: -r * 0.35)
                .shadow(color: ForgeTheme.iconGlow.opacity(0.4), radius: r * 0.06)

            // Hammer + anvil
            HammerAnvilShape()
                .fill(
                    LinearGradient(
                        colors: [
                            ForgeTheme.iconGoldLight.opacity(0.95),
                            ForgeTheme.iconGold,
                            ForgeTheme.iconGold.opacity(0.85)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    HammerAnvilShape()
                        .stroke(ForgeTheme.iconGoldLight.opacity(0.4), lineWidth: max(1, r / 150))
                )
                .frame(width: r * 0.7, height: r * 0.45)
                .offset(y: r * 0.12)
                .shadow(color: .black.opacity(0.35), radius: r * 0.03, x: 0, y: r * 0.01)
        }
    }

    // MARK: - Variation B: Hammer striking star spark
    private func hammerSparkContent(cx: CGFloat, cy: CGFloat, r: CGFloat) -> some View {
        ZStack {
            ForgeIconRing(radius: r * 0.72, lineWidth: max(2, r / 80))
            // Spark at center (small star burst)
            Image(systemName: "sparkles")
                .font(.system(size: r * 0.35, weight: .medium))
                .foregroundStyle(ForgeTheme.iconGoldLight)
                .shadow(color: ForgeTheme.iconGlow.opacity(0.6), radius: r * 0.05)
            // Hammer coming down (tilted)
            HammerAnvilShape(hammerOnly: true)
                .fill(
                    LinearGradient(
                        colors: [ForgeTheme.iconGoldLight, ForgeTheme.iconGold],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: r * 0.5, height: r * 0.5)
                .rotationEffect(.degrees(-25))
                .offset(y: -r * 0.05)
        }
    }

    // MARK: - Variation C: Minimal north star only
    private func starOnlyContent(cx: CGFloat, cy: CGFloat, r: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            ForgeTheme.iconGlow.opacity(0.45),
                            ForgeTheme.iconGold.opacity(0.15),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: r * 0.6
                    )
                )
                .frame(width: r * 1.2, height: r * 1.2)
                .blur(radius: r * 0.08)
            ForgeIconRing(radius: r * 0.55, lineWidth: max(2, r / 70))
            NorthStarShape()
                .fill(
                    LinearGradient(
                        colors: [ForgeTheme.iconGoldLight, ForgeTheme.iconGold],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    NorthStarShape()
                        .stroke(ForgeTheme.iconGoldLight.opacity(0.5), lineWidth: max(1, r / 100))
                )
                .frame(width: r * 0.7, height: r * 0.7)
                .shadow(color: ForgeTheme.iconGlow.opacity(0.35), radius: r * 0.05)
        }
    }
}

// MARK: - Minimal alchemy ring (double circle, no symbols)
private struct ForgeIconRing: View {
    let radius: CGFloat
    let lineWidth: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(ForgeTheme.iconGold.opacity(0.9), lineWidth: lineWidth)
                .frame(width: radius * 2, height: radius * 2)
            Circle()
                .stroke(ForgeTheme.iconGold.opacity(0.6), lineWidth: lineWidth * 0.6)
                .frame(width: radius * 2 * 0.88, height: radius * 2 * 0.88)
        }
    }
}

// MARK: - 8-point north star shape (strong silhouette)
private struct NorthStarShape: Shape {
    func path(in rect: CGRect) -> Path {
        let cx = rect.midX
        let cy = rect.midY
        let outer = min(rect.width, rect.height) * 0.48
        let inner = outer * 0.4
        var path = Path()
        for i in 0..<8 {
            let a1 = Angle(degrees: Double(i) * 45)
            let a2 = Angle(degrees: Double(i) * 45 + 22.5)
            let x1 = cx + outer * CGFloat(cos(a1.radians))
            let y1 = cy + outer * CGFloat(sin(a1.radians))
            let x2 = cx + inner * CGFloat(cos(a2.radians))
            let y2 = cy + inner * CGFloat(sin(a2.radians))
            if i == 0 { path.move(to: CGPoint(x: x1, y: y1)) }
            else { path.addLine(to: CGPoint(x: x1, y: y1)) }
            path.addLine(to: CGPoint(x: x2, y: y2))
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Hammer and anvil (simplified, recognizable at small sizes)
private struct HammerAnvilShape: Shape {
    var hammerOnly: Bool = false

    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()
        if hammerOnly {
            // Hammer head
            let headRect = CGRect(x: w * 0.2, y: h * 0.05, width: w * 0.35, height: h * 0.25)
            path.addPath(Path(roundedRect: headRect, cornerRadius: min(headRect.width, headRect.height) * 0.15, style: .continuous))
            // Handle
            path.move(to: CGPoint(x: w * 0.42, y: h * 0.28))
            path.addLine(to: CGPoint(x: w * 0.5, y: h * 0.95))
            path.addLine(to: CGPoint(x: w * 0.58, y: h * 0.95))
            path.addLine(to: CGPoint(x: w * 0.58, y: h * 0.28))
            path.closeSubpath()
        } else {
            // Anvil: flat top, horn, base
            path.move(to: CGPoint(x: w * 0.08, y: h * 0.5))
            path.addLine(to: CGPoint(x: w * 0.92, y: h * 0.5))
            path.addLine(to: CGPoint(x: w * 0.85, y: h * 0.72))
            path.addLine(to: CGPoint(x: w * 0.15, y: h * 0.72))
            path.closeSubpath()
            path.addEllipse(in: CGRect(x: w * 0.35, y: h * 0.72, width: w * 0.3, height: h * 0.2))
            // Hammer head
            let headRect = CGRect(x: w * 0.22, y: h * 0.08, width: w * 0.28, height: h * 0.22)
            path.addPath(Path(roundedRect: headRect, cornerRadius: min(headRect.width, headRect.height) * 0.12, style: .continuous))
            // Hammer handle
            path.move(to: CGPoint(x: w * 0.38, y: h * 0.28))
            path.addLine(to: CGPoint(x: w * 0.44, y: h * 0.48))
            path.addLine(to: CGPoint(x: w * 0.5, y: h * 0.48))
            path.addLine(to: CGPoint(x: w * 0.5, y: h * 0.28))
            path.closeSubpath()
        }
        return path
    }
}

// MARK: - Preview & export
#if DEBUG
struct AppIconView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 24) {
            HStack(spacing: 24) {
                AppIconView(variation: .standard, size: 120)
                AppIconView(variation: .hammerSpark, size: 120)
                AppIconView(variation: .starOnly, size: 120)
            }
            AppIconView(variation: .standard, size: 256)
        }
        .padding()
        .background(ForgeTheme.iconNavy)
        .preferredColorScheme(.light)
    }
}
#endif
