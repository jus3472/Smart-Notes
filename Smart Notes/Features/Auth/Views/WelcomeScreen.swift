import SwiftUI

struct WelcomeScreen: View {
    var onContinue: () -> Void

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {

                // ============================
                // HEADER (Logo + Smart Notes)
                // ============================
                ZStack {
                    Image("Vector 2")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, alignment: .top)
                        .ignoresSafeArea(edges: .top)

                    VStack(spacing: -5) {
                        Image("SmartNotesLogo 1")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)

                        Text("Smart Notes")
                            .font(.largeTitle.bold())
                            .foregroundColor(.white)
                    }
                    .padding(.top, -100)
                }
                .frame(maxWidth: .infinity, alignment: .top)


                Spacer()


                // ============================
                // BOTTOM CONTENT
                // ============================
                VStack(alignment: .leading, spacing: 14) {

                    // --- TEXT GROUP (moves up independently) ---
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Welcome")
                            .font(.largeTitle.bold())
                            .foregroundColor(.black)

                        Text("Get notes that are simple yet smart")
                            .font(.body)
                            .foregroundColor(.gray)
                    }
                    .offset(y: -40)   // << move ONLY these texts up


                    // --- BUTTON GROUP (stays fixed + full width) ---
                    HStack {
                        Spacer()
                        Button(action: onContinue) {
                            HStack(spacing: 10) {
                                Text("Continue")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.gray)

                                ZStack {
                                    Image("Ellipse 24")
                                        .resizable()
                                        .frame(width: 44, height: 44)

                                    Image(systemName: "arrow.right")
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    }
                    .padding(.top, 16)

                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)   // how close entire bottom section is to bottom
            }
        }
    }
}

struct WelcomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeScreen { }
    }
}
