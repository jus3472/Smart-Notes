// AuthViewModel.swift
import Foundation
import FirebaseAuth

final class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    
    private let auth = FirebaseManager.shared.auth
    
    /// auth listener handle 저장 변수
    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    
    init() {
        // 초기 사용자 설정
        self.user = auth.currentUser
        
        // 리스너 등록 + handle 저장
        authStateListenerHandle = auth.addStateDidChangeListener { [weak self] _, user in
            self?.user = user
        }
    }
    
    deinit {
        // 리스너 제거 (메모리 누수 방지)
        if let handle = authStateListenerHandle {
            auth.removeStateDidChangeListener(handle)
        }
    }
    
    var isLoggedIn: Bool {
        user != nil
    }
    
    func signIn() {
        isLoading = true
        errorMessage = nil
        
        auth.signIn(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                self.isLoading = false
                if let error = error {
                    self.errorMessage = error.localizedDescription
                } else {
                    self.user = result?.user
                }
            }
        }
    }
    
    func signUp() {
        isLoading = true
        errorMessage = nil
        
        auth.createUser(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                self.isLoading = false
                if let error = error {
                    self.errorMessage = error.localizedDescription
                } else {
                    self.user = result?.user
                }
            }
        }
    }
    
    func signOut() {
        do {
            try auth.signOut()
            user = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    var uid: String? {
        user?.uid
    }
}
