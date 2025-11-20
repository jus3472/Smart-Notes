import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationStack {
            List {
                // MARK: - Profile / Account section
                Section {
                    HStack(spacing: 16) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.accentColor)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(authViewModel.user?.email ?? "Signed in")
                                .font(.headline)
                            
                            if let email = authViewModel.user?.email {
                                Text(email)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Email & password login")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Account")
                }
                
                // MARK: - About section
                Section("About") {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text(appVersionString)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label("Made with", systemImage: "sparkles")
                        Spacer()
                        Text("SwiftUI & Firebase")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    }
                }
                
                // MARK: - Sign out
                Section {
                    Button(role: .destructive) {
                        authViewModel.signOut()
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
    
    // Helper: app version from bundle (falls back gracefully)
    private var appVersionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        return build.isEmpty ? version : "\(version) (\(build))"
    }
}
