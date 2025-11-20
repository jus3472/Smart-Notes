import SwiftUI

struct SignUpScreen: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    var onLoginTapped: () -> Void

    @State private var confirmPassword: String = ""

    // Match login colors
    let underlineBlue = Color(hex: "1B75DF")
    let accentBlue    = Color(hex: "78ABE8")

    // For keyboard focus + dismissal
    @FocusState private var focusedField: Field?

    enum Field {
        case email
        case password
        case confirm
    }

    var body: some View {
        ZStack(alignment: .top) {

            // Blue patterned header with wave
            Image("Vector 2")
                .resizable()
                .scaledToFill()
                .frame(height: 180)
                .offset(y: 20)
                .ignoresSafeArea(edges: .top)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // Push content down so title sits in the wave dip
                    Spacer().frame(height: 230)

                    // "Sign up" title + blue underline
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Sign up")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.black)

                        Rectangle()
                            .fill(underlineBlue)
                            .frame(width: 90, height: 4)
                            .cornerRadius(2)
                    }
                    .padding(.horizontal, 24)

                    // FORM SECTION
                    VStack(spacing: 24) {

                        // Email
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Email")
                                .font(.caption)
                                .foregroundColor(.gray)

                            TextField("Enter your email", text: $authViewModel.email)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .padding(.vertical, 8)
                                .focused($focusedField, equals: .email)

                            Divider().background(Color.gray.opacity(0.2))
                        }

                        // Password
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Password")
                                .font(.caption)
                                .foregroundColor(.gray)

                            SecureField("Enter your password", text: $authViewModel.password)
                                .padding(.vertical, 8)
                                .focused($focusedField, equals: .password)

                            Divider().background(Color.gray.opacity(0.2))
                        }

                        // Confirm password
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Confirm Password")
                                .font(.caption)
                                .foregroundColor(.gray)

                            SecureField("Confirm your password", text: $confirmPassword)
                                .padding(.vertical, 8)
                                .focused($focusedField, equals: .confirm)

                            Divider().background(Color.gray.opacity(0.2))
                        }

                        // Error message
                        if let error = authViewModel.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        // Create Account button
                        Button {
                            guard confirmPassword == authViewModel.password else {
                                // hook into your VM if you want an error
                                return
                            }
                            authViewModel.signUp()
                        } label: {
                            Text("Create Account")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(accentBlue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding(.top, 8)

                        // Bottom text link
                        HStack(spacing: 4) {
                            Text("Already have an Account?")
                                .foregroundColor(.gray)
                            Button("Login") {
                                onLoginTapped()
                            }
                            .foregroundColor(accentBlue)
                        }
                        .font(.footnote)

                        // Extra bottom padding so it doesn't feel cramped above keyboard
                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                }
                // Tap anywhere in the scroll area to dismiss keyboard
                .contentShape(Rectangle())
                .onTapGesture {
                    focusedField = nil
                }
            }
        }
        // Don't animate layout changes when focus changes (removes the “bounce” feel)
        .animation(.none, value: focusedField)
        // Let keyboard overlap bottom instead of pushing everything hard
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .background(Color.white.ignoresSafeArea())
    }
}

struct SignUpScreen_Previews: PreviewProvider {
    static var previews: some View {
        SignUpScreen { }
            .environmentObject(AuthViewModel())
    }
}
