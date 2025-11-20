import SwiftUI

struct SplashView: View {
    @Binding var showSplash: Bool
    @State private var logoScale: CGFloat = 0.6
    @State private var logoOpacity: Double = 0.0
    @State private var textOffset: CGFloat = 20
    @State private var textOpacity: Double = 0.0
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color(.secondarySystemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // App icon / logo
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.12))
                        .frame(width: 140, height: 140)
                    
                    Image(systemName: "note.text")
                        .font(.system(size: 60, weight: .semibold))
                        .foregroundColor(.accentColor)
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)
                
                // App name and tagline
                VStack(spacing: 6) {
                    Text("Smart Notes")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                    
                    Text("Record. Summarize. Remember.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .opacity(textOpacity)
                .offset(y: textOffset)
            }
        }
        .onAppear {
            animateIn()
        }
    }
    
    private func animateIn() {
        // 1) Logo pop-in
        withAnimation(.spring(response: 0.7, dampingFraction: 0.7, blendDuration: 0.3)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        // 2) Tagline fade up
        withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
            textOpacity = 1.0
            textOffset = 0
        }
        
        // 3) Fade out to main app
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(.easeInOut(duration: 0.4)) {
                showSplash = false
            }
        }
    }
}
