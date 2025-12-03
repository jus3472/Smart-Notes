import SwiftUI

struct LoginScreen: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    var onSignUpTapped: () -> Void

    @State private var rememberMe = false

    let underlineBlue = Color(hex: "1B75DF")
    let accentBlue    = Color(hex: "78ABE8")

    // MARK: - Focus handling
    enum Field {
        case email
        case password
    }

    @FocusState private var focusedField: Field?

    // Any field focused?
    private var isKeyboardActive: Bool {
        focusedField != nil
    }

    var body: some View {
        ZStack(alignment: .top) {

            // HEADER IMAGE (wave)
            VStack(spacing: 0) {
                Image("Vector 2")
                    .resizable()
                    .scaledToFill()
                    .frame(height: 260)
                    .offset(y: 20)      // your tuned position
                    .ignoresSafeArea(edges: .top)

                Spacer().frame(height: 0)
            }

            // CONTENT (title + form)
            VStack(alignment: .leading, spacing: 0) {

                // Push down so Login title sits in wave dip
                Spacer().frame(height: 260)

                // LOGIN TITLE
                VStack(alignment: .leading, spacing: 6) {
                    Text("Login")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.black)

                    Rectangle()
                        .fill(underlineBlue)
                        .frame(width: 70, height: 4)
                        .cornerRadius(2)
                }
                .padding(.horizontal, 24)

                // FORM
                VStack(spacing: 24) {

                    // Email
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Email")
                            .foregroundColor(.gray)
                            .font(.caption)

                        TextField("Enter your email", text: $authViewModel.email)
                            .textInputAutocapitalization(.never)
                            .padding(.vertical, 8)
                            .foregroundColor(.black)          // 👈 입력 텍스트 색상
                            .focused($focusedField, equals: .email)

                        Divider().background(Color.gray.opacity(0.2))
                    }

                    // Password
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Password")
                            .foregroundColor(.gray)
                            .font(.caption)

                        SecureField("Enter your password", text: $authViewModel.password)
                            .padding(.vertical, 8)
                            .foregroundColor(.black)          // 👈 입력 텍스트 색상
                            .focused($focusedField, equals: .password)

                        Divider().background(Color.gray.opacity(0.2))
                    }

                    // Error
                    if let error = authViewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }

                    // Remember + Forgot
                    HStack {
                        Button {
                            rememberMe.toggle()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: rememberMe ? "checkmark.square" : "square")
                                Text("Remember Me")
                                    .foregroundColor(.gray)
                                    .font(.caption)
                            }
                        }

                        Spacer()

                        Button("Forgot Password?") {}
                            .font(.caption)
                            .foregroundColor(accentBlue)
                    }

                    // Login button
                    Button {
                        authViewModel.signIn()
                    } label: {
                        Text("Login")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(accentBlue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.top, 8)

                    // Bottom text
                    HStack(spacing: 4) {
                        Text("Don’t have an Account?")
                            .foregroundColor(.gray)
                        Button("Sign up") {
                            onSignUpTapped()
                        }
                        .foregroundColor(accentBlue)
                    }
                    .font(.footnote)

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)

                Spacer()
            }
            // tap anywhere in content to dismiss keyboard
            .contentShape(Rectangle())
            .onTapGesture {
                focusedField = nil
            }
        }
        // 👇 move the WHOLE screen (wave + content) when keyboard is active
        .offset(y: isKeyboardActive ? -180 : 0)   // tweak -180 as needed
        .animation(.easeOut(duration: 0.2), value: isKeyboardActive)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .background(Color.white.ignoresSafeArea())
    }
}

struct LoginScreen_Previews: PreviewProvider {
    static var previews: some View {
        LoginScreen { }
            .environmentObject(AuthViewModel())
    }
}
