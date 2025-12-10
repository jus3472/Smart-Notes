import SwiftUI

struct SplashView: View {
    @Binding var showSplash: Bool
    
    // Logo animation states
    @State private var bookOpen = false
    @State private var logoScale: CGFloat = 0.7
    @State private var logoGlow = false
    
    // Text animation
    @State private var textOpacity: Double = 0.0
    @State private var textOffset: CGFloat = 20
    
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
            
            VStack(spacing: 28) {
                
                ZStack {
                    // Soft glow halo behind logo
                    Circle()
                        .fill(Color.accentColor.opacity(0.12))
                        .frame(width: 160, height: 160)
                        .scaleEffect(logoGlow ? 1.05 : 1.0)
                        .animation(
                            .easeInOut(duration: 1.3)
                                .repeatForever(autoreverses: true),
                            value: logoGlow
                        )
                    
                    // Main app logo
                    Image("logo")   // <-- using your logo.png
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .rotation3DEffect(
                            .degrees(bookOpen ? 0 : 45), // LEFT → RIGHT open direction
                            axis: (x: 0, y: 1, z: 0),     // y-axis flip
                            anchor: .center
                        )
                        .scaleEffect(logoScale)
                        .shadow(color: .black.opacity(0.15),
                                radius: 10, x: 0, y: 6)
                }
                
                // App Title + Tagline
                VStack(spacing: 6) {
                    Text("Smart Notes")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                    
                    Text("Record. Summarize. Remember.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .opacity(textOpacity)
                .offset(y: textOffset)
            }
        }
        .onAppear { animateIn() }
    }
    
    // MARK: - Animations
    
    private func animateIn() {
        logoGlow = true
        
        // Book open + scale pop
        withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) {
            bookOpen = true
            logoScale = 1.0
        }
        
        // Text fade-in
        withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
            textOpacity = 1.0
            textOffset = 0
        }
        
        // Splash dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.4)) {
                showSplash = false
            }
        }
    }
}
