//
//  EditProfile.swift
//  MoviesApp
//
//  Created by Reema Alsaleh  on 12/07/1447 AH.
//

import SwiftUI
struct EditProfileView: View {
    @Binding var profile: AirtableRecordR<Profile>   // <--- الربط مع ViewModel
    
    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false
    
    // نسخة مؤقتة لتعديل الحقول بدون التأثير على النسخة الأصلية
    @State private var tempProfile: Profile

    // تهيئة tempProfile بقيم النسخة الأصلية عند فتح الصفحة
    init(profile: Binding<AirtableRecordR<Profile>>) {
        self._profile = profile
        self._tempProfile = State(initialValue: profile.wrappedValue.fields)
    }
    
    var body: some View {
        VStack(spacing: 30) {
            
            // Avatar
            ZStack {
                if let urlString = tempProfile.profile_image,
                   let url = URL(string: urlString),
                   !urlString.isEmpty {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        default:
                            Image(systemName: "person.fill")
                                .foregroundColor(.white)
                        }
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.fill")
                        .resizable()
                        .padding(20)
                        .frame(width: 80, height: 80)
                        .background(Color.gray.opacity(0.3))
                        .clipShape(Circle())
                        .foregroundColor(.white)
                }

                if isEditing {
                    Circle()
                        .fill(Color.black.opacity(0.6))
                        .frame(width: 80, height: 80)

                    Image(systemName: "camera.fill")
                        .foregroundColor(Color("Warning"))
                        .font(.system(size: 20))
                }
            }
            .padding(.top, 20)
            
            // الحقول (Names Section)
            VStack(spacing: 0) {
                // First Name Row
                HStack {
                    Text("First Name")
                        .foregroundColor(.white)
                        .frame(width: 100, alignment: .leading)
                    
                    TextField("", text: Binding(
                        get: { tempProfile.firstName },
                        set: { newFirst in
                            tempProfile.name = newFirst + " " + tempProfile.lastName
                        }
                    ))
                    .foregroundColor(.white)
                    .disabled(!isEditing)
                }
                .padding()
                
                Divider().background(Color.dark3.opacity(0.3))
                    .padding(.horizontal,15)
                
                // Last Name Row
                HStack {
                    Text("Last Name")
                        .foregroundColor(.white)
                        .frame(width: 100, alignment: .leading)
                    
                    TextField("", text: Binding(
                        get: { tempProfile.lastName },
                        set: { newLast in
                            tempProfile.name = tempProfile.firstName + " " + newLast
                        }
                    ))
                    .foregroundColor(.white)
                    .disabled(!isEditing)
                }
                .padding()
            }
            .background(Color(white: 0.12))
            .cornerRadius(12)
            .padding(.horizontal, 16)
            
            Spacer()
            
            // Sign Out Button
            Button {
                print("Sign Out tapped")
            } label: {
                Text("Sign Out")
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.dark2)
                    .cornerRadius(12)
                    .padding(.horizontal, 24)
            }
            .padding(.bottom, 20)
        }
        .background(Color.black.ignoresSafeArea())
        .navigationTitle(isEditing ? "Edit Profile" : "Profile Info")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(Color("Warning"))
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "Save" : "Edit") {
                    if isEditing {
                        // فقط عند الضغط على Save، نحدث النسخة الأصلية ونرسل التحديث للـ API
                        profile.fields = tempProfile
                        Task {
                            await APIServices().saveProfileToAPI(profilerecord(
                                id: profile.id,
                                createdTime: profile.createdTime,
                                fields: profile.fields
                            ))
                        }
                    }
                    isEditing.toggle()
                }
                .foregroundColor(Color("Warning"))
            }
        }
    }
}
#Preview {
    ProfileView()
        .preferredColorScheme(.dark)
}

