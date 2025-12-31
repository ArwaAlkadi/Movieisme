//
//  SignInViewModel.swift
//  MoviesApp
//
//  Created by Arwa Alkadi on 24/12/2025.
//

import Foundation
import Combine

class SignInViewModel: ObservableObject {
    
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isPasswordVisible: Bool = false
    @Published var showError: Bool = false
    @Published var emailError: Bool = false  
    @Published var passwordError: Bool = false
    
    var isSignInButtonEnabled: Bool {
        get {
            return !self.email.isEmpty && !self.password.isEmpty
        }
    }
    
    func signIn() {
        
        print("Email: \(self.email)")
        print("Password: \(self.password)")
    }
    
    func togglePasswordVisibility() {
        self.isPasswordVisible.toggle()
    }
}
