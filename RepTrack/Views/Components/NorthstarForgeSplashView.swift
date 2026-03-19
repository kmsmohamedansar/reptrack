//
//  NorthstarForgeSplashView.swift
//  RepTrack
//
//  Launch splash: Northstar Forge logo with entrance animation.
//

import SwiftUI

struct NorthstarForgeSplashView: View {
    @State private var logoScale: CGFloat = 0.75
    @State private var logoOpacity: Double = 0

    var body: some View {
        ZStack {
            // Full-screen navy background (no white edges)
            ForgeTheme.splashNavyGradient
                .ignoresSafeArea(.all)

            // Logo centered in the middle
            logoView
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                logoScale = 1
                logoOpacity = 1
            }
        }
    }

    private var logoView: some View {
        ZStack {
            // Soft gold glow behind logo
            Circle()
                .fill(ForgeTheme.gold.opacity(0.12))
                .frame(width: 280, height: 280)
                .blur(radius: 50)

            Image("NorthstarForgeLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 260, maxHeight: 260)
                .scaleEffect(logoScale)
                .opacity(logoOpacity)
        }
    }
}

#Preview {
    NorthstarForgeSplashView()
        .preferredColorScheme(.light)
}
