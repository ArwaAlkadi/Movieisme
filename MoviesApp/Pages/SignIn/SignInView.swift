//
//  SignInView.swift
//  MoviesApp
//
//  Created by Arwa Alkadi on 24/12/2025.
//

import SwiftUI

struct SignInView: View {
    
    @StateObject private var viewModel = SignInViewModel()
    
    var body: some View {
        ZStack {
            Image("SignInBG")
                .resizable()
                .ignoresSafeArea()
            
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: .clear, location: 0.0),                    // شفاف - بداية الثلث الأول
                    .init(color: Color.black.opacity(0.15), location: 0.33), // شوية غمقة خفيفة - نهاية الثلث الأول
                    .init(color: Color.black.opacity(0.5), location: 0.45),  // تدرج متوسط
                    .init(color: Color.black.opacity(0.7), location: 0.55),  // تدرج قوي
                    .init(color: Color.black.opacity(0.85), location: 0.70), // تدرج أقوى
                    .init(color: Color.black.opacity(0.95), location: 0.85), // شبه أسود كامل
                    .init(color: .black, location: 0.95),                    // أسود كامل
                    .init(color: .black, location: 1.0)                      // أسود لآخر الشاشة
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack (spacing: 30) {
                
                Spacer()// يدف الكلام بالنص
                    .frame(height: 350) //هنا اتحكم بمكان كلمه ساين ان والكلام اللي تحته بشكل طولي
                
                
                VStack(alignment: .leading, spacing: 10 ) {
                    Text("Sign in")
                        .font(.system(size: 40,weight: .bold)) //جحم الخط
                        .foregroundColor(.white)
                    
                    Text("You'll find what you what you're looking for in the ocean of movies")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                    
                }
                .frame (maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 30)
                
                // حقل الإيميل (نفسه بس عدلنا شوي)
                VStack(alignment: .leading, spacing: 5){
                    Text("Email")
                        .foregroundColor(.white)
                        .font(.system(size: 14))
                    CustomTextField(
                        placeholder: "Enter your email",
                        text: $viewModel.email,
                        isSecure: false,
                        isPasswordVisible: .constant(false),
                        onToggleVisibility: nil,
                        hasError: $viewModel.emailError  // جديد
                    )
                }
                .padding(.horizontal, 30)

                // حقل الباسورد (جديد كامل!)
                VStack(alignment: .leading, spacing: 5){
                    Text("Password")
                        .foregroundColor(.white)
                        .font(.system(size: 14))
                    CustomTextField(
                        placeholder: "Enter your password",
                        text: $viewModel.password,
                        isSecure: true,
                        isPasswordVisible: $viewModel.isPasswordVisible,
                        onToggleVisibility: {
                            viewModel.togglePasswordVisibility()
                        },
                        hasError: $viewModel.passwordError  // جديد
                    )             }
                .padding(.horizontal, 30)
                
                // زر Sign In - جديد!
                Button(action: {
                    viewModel.signIn()
                }) {
                    Text("Sign in")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(viewModel.isSignInButtonEnabled ? .black : Color(red: 0.5, green: 0.5, blue: 0.5))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(viewModel.isSignInButtonEnabled ? Color("MainColor1") : Color("Dark4"))
                        .cornerRadius(10)
                }
                .disabled(!viewModel.isSignInButtonEnabled)
                .padding(.horizontal, 30)

                Spacer()            }
        }
    }
}

struct CustomTextField: View {
    
    var placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    @Binding var isPasswordVisible: Bool
    var onToggleVisibility: (() -> Void)?
    @Binding var hasError: Bool  // جديد: عشان نعرف فيه خطأ
    
    @FocusState private var isFocused: Bool  // جديد: عشان نعرف الحقل مضغوط
    
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
                            .focused($isFocused)  // جديد
                    } else {
                        TextField("", text: $text)
                            .focused($isFocused)  // جديد
                    }
                }
                .foregroundColor(.white)
                .autocapitalization(.none)
                .accentColor(Color("MainColor1"))  // جديد: لون الكيرسر (الخط)
            }
            
            if isSecure {
                Button(action: {
                    onToggleVisibility?()
                }) {
                    Image(systemName: isPasswordVisible ? "eye.fill" : "eye.slash.fill")
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 24, height: 24)
                }
            }
        }
        .padding()
        .background(Color("Dark3"))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(borderColor, lineWidth: 2)  // جديد: البوردر
        )
    }
    
    // جديد: دالة تحدد لون البوردر
    private var borderColor: Color {
        if hasError {
            return Color("Error")  // أحمر لو فيه خطأ
        } else if isFocused {
            return Color("MainColor1")  // أصفر لو مضغوط
        } else {
            return Color.clear  // شفاف لو عادي
        }
    }
}
#Preview {
    SignInView()
}
