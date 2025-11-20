import SwiftUI

enum AuthStep {
    case welcome
    case login
    case signup
}

struct AuthView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var step: AuthStep = .welcome

    var body: some View {
        NavigationStack {
            content
                .animation(.easeInOut, value: step)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case .welcome:
            WelcomeScreen {
                step = .login
            }

        case .login:
            LoginScreen {
                step = .signup
            }

        case .signup:
            SignUpScreen {
                step = .login
            }
        }
    }
}

struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView()
            .environmentObject(AuthViewModel())
    }
}
