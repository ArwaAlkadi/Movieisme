//
//  SignInViewModel.swift
//  MoviesApp
//
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class SignInViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isPasswordVisible: Bool = false

    @Published var emailError: Bool = false
    @Published var passwordError: Bool = false

    @Published var isLoading: Bool = false

    @Published var errorMessage: String?
    @Published var showErrorAlert: Bool = false

    private let api: APIServices

    //  MARK: -  Profiles from unified cache

    var profiles: [ProfileDTO] { api.profiles }

    var isSignInButtonEnabled: Bool {
        !email.isEmpty && !password.isEmpty && !isLoading
    }

    init(api: APIServices) {
        self.api = api
    }

    func togglePasswordVisibility() {
        isPasswordVisible.toggle()
    }

    func fetchProfiles() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await api.fetchProfiles()
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }

    func signIn(onSuccess: @escaping (String) -> Void) {

        /// Reset errors
        emailError = false
        passwordError = false
        errorMessage = nil

        /// Validate email
        guard !email.isEmpty else {
            emailError = true
            errorMessage = "Please enter your email"
            showErrorAlert = true
            return
        }

        /// Validate password
        guard !password.isEmpty else {
            passwordError = true
            errorMessage = "Please enter your password"
            showErrorAlert = true
            return
        }

        /// Find user by email
        guard let user = api.getProfileByEmail(email) else {
            emailError = true
            errorMessage = "Email not found"
            showErrorAlert = true
            return
        }

        /// Check password
        guard user.fields.password == password else {
            passwordError = true
            errorMessage = "Incorrect password"
            showErrorAlert = true
            return
        }

        /// Success
        onSuccess(user.id)
    }
}
