//
//  SignInView.swift
//  MoviesApp
//
//

import SwiftUI

struct SignInView: View {

    @EnvironmentObject private var session: SessionManager

    @ObservedObject var api: APIServices
    @StateObject private var viewModel: SignInViewModel

    init(api: APIServices) {
        self.api = api
        _viewModel = StateObject(wrappedValue: SignInViewModel(api: api))
    }

    var body: some View {
        ZStack {

            background
                .ignoresSafeArea()
                .ignoresSafeArea(.keyboard)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 30) {

                    Spacer()
                        .frame(height: 330)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Sign in")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)

                        Text("You'll find what you're looking for in the ocean of movies")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 15)

                    // MARK: -  Email Field
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Email")
                            .foregroundColor(.white)
                            .font(.system(size: 16))

                        CustomTextField(
                            placeholder: "Enter your email",
                            text: $viewModel.email,
                            isSecure: false,
                            isPasswordVisible: .constant(false),
                            onToggleVisibility: nil,
                            hasError: $viewModel.emailError
                        )
                    }
                    .padding(.horizontal, 15)

                    // MARK: - Password Field
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Password")
                            .foregroundColor(.white)
                            .font(.system(size: 16))

                        CustomTextField(
                            placeholder: "Enter your password",
                            text: $viewModel.password,
                            isSecure: true,
                            isPasswordVisible: $viewModel.isPasswordVisible,
                            onToggleVisibility: {
                                viewModel.togglePasswordVisibility()
                            },
                            hasError: $viewModel.passwordError
                        )
                    }
                    .padding(.horizontal, 15)


                    // MARK: -  Sign In Button
                    Button(action: {
                        viewModel.signIn { userID in
                            session.signIn(userID: userID)
                        }
                    }) {
                        ZStack {
                            Text("Sign in")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(viewModel.isSignInButtonEnabled ? .black : .dark3)
                                .frame(width: 358, height: 44)
                                .background(viewModel.isSignInButtonEnabled ? Color("MainColor1") : Color("Dark4"))
                                .cornerRadius(10)
                                .opacity(viewModel.isLoading ? 0.6 : 1.0)

                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.black)
                                    .scaleEffect(1.2)
                            }
                        }
                    }
                    .disabled(!viewModel.isSignInButtonEnabled)
                    .padding(.horizontal, 15)

                    // MARK: - ✅ زر الدخول كضيف
                    Button {
                        session.continueAsGuest()
                    } label: {
                        Text("Continue as Guest")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color("MainColor1"))
                            .frame(width: 358, height: 44)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color("MainColor1"), lineWidth: 1.2)
                            )
                    }
                    .padding(.horizontal, 15)
                    .padding(.top, -10)

                    Spacer(minLength: 40)
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .task {
            await viewModel.fetchProfiles()
        }
        .alert("Error", isPresented: $viewModel.showErrorAlert) {
            Button("OK", role: .cancel) {
                viewModel.showErrorAlert = false
            }
        } message: {
            Text(viewModel.errorMessage ?? "Unknown error")
        }
    }

    private var background: some View {
        ZStack {
            Image("SignInBG")
                .resizable()

            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: .clear, location: 0.0),
                    .init(color: Color.black.opacity(0.15), location: 0.33),
                    .init(color: Color.black.opacity(0.5), location: 0.45),
                    .init(color: Color.black.opacity(0.7), location: 0.55),
                    .init(color: Color.black.opacity(0.85), location: 0.70),
                    .init(color: Color.black.opacity(0.95), location: 0.85),
                    .init(color: .black, location: 0.95),
                    .init(color: .black, location: 1.0)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}





struct CustomTextField: View {

    var placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    @Binding var isPasswordVisible: Bool
    var onToggleVisibility: (() -> Void)?
    @Binding var hasError: Bool

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack {
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundColor(Color(red: 0.7, green: 0.7, blue: 0.7))
                }

                Group {
                    if isSecure && !isPasswordVisible {
                        SecureField("", text: $text)
                            .focused($isFocused)
                    } else {
                        TextField("", text: $text)
                            .focused($isFocused)
                    }
                }
                .foregroundColor(.white)
                .autocapitalization(.none)
                .accentColor(Color("MainColor1"))
            }

            if isSecure {
                Button(action: {
                    onToggleVisibility?()
                }) {
                    Image(systemName: isPasswordVisible ? "eye.fill" : "eye.slash.fill")
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 20, height: 20)
                }
            }
        }
        .padding()
        .frame(width: 358, height: 44)
        .background(Color("Dark3"))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(borderColor, lineWidth: 2)
        )
    }

    private var borderColor: Color {
        if hasError {
            return Color("Error")
        } else if isFocused {
            return Color("MainColor1")
        } else {
            return Color.clear
        }
    }
}





#Preview {
    SignInView(api: APIServices())
        .environmentObject(SessionManager())
}
