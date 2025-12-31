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
                        isSecure: false,  // جديد: نقول له مو باسورد
                        isPasswordVisible: .constant(false),  // جديد: مو مهم هنا
                        onToggleVisibility: nil  // جديد: ما فيه عين للإيميل
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
                        isSecure: true,  // جديد: نقول له هذا باسورد
                        isPasswordVisible: $viewModel.isPasswordVisible,  // جديد: متغير يتحكم بالعين
                        onToggleVisibility: {  // جديد: لما نضغط العين
                            viewModel.togglePasswordVisibility()
                        }
                    )
                }
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
    
    var body: some View {
        HStack {
            ZStack(alignment: .leading) {
                // الـ placeholder (يظهر لما الحقل فاضي)
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundColor(Color(red: 0.7, green: 0.7, blue: 0.7)) // لون فاتح #B3B3B3
                }
                
                // الحقل نفسه
                Group {
                    if isSecure && !isPasswordVisible {
                        SecureField("", text: $text)
                    } else {
                        TextField("", text: $text)
                    }
                }
                .foregroundColor(.white)
                .autocapitalization(.none)
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
    }
}
#Preview {
    SignInView()
}
