//
//  SignInViewModel.swift
//  MoviesApp
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

    /// Validates the credentials against the cached profiles.
    /// Session persistence is handled by SessionManager in the view layer.
    func signIn(onSuccess: @escaping (String) -> Void) {

        emailError = false
        passwordError = false
        errorMessage = nil

        guard !email.isEmpty else {
            emailError = true
            errorMessage = "Please enter your email"
            showErrorAlert = true
            return
        }

        guard !password.isEmpty else {
            passwordError = true
            errorMessage = "Please enter your password"
            showErrorAlert = true
            return
        }

        guard let user = api.getProfileByEmail(email) else {
            emailError = true
            errorMessage = "Email not found"
            showErrorAlert = true
            return
        }

        guard user.fields.password == password else {
            passwordError = true
            errorMessage = "Incorrect password"
            showErrorAlert = true
            return
        }

        onSuccess(user.id)
    }
}
