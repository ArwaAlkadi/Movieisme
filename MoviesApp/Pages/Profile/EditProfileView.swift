//
//   EditProfileView.swift
//  MoviesApp
//
//

import SwiftUI

struct EditProfileView: View {

    @ObservedObject var vm: ProfileViewModel
    @Binding var profile: ProfileDTO

    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false

    @State private var tempProfile: ProfileFields

    init(vm: ProfileViewModel, profile: Binding<ProfileDTO>) {
        self.vm = vm
        self._profile = profile
        self._tempProfile = State(initialValue: profile.wrappedValue.fields)
    }

    var body: some View {
        VStack(spacing: 30) {

            // MARK: -  Avatar
            ZStack {
                if let urlString = tempProfile.profile_image,
                   let url = URL(string: urlString),
                   !urlString.isEmpty {

                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
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

            // MARK: -  Fields
            VStack(spacing: 0) {

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
                    .padding(.horizontal, 15)

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

            if !isEditing {
                NavigationLink {
                    SignInView()
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
        }
        .background(Color.black.ignoresSafeArea())
        .navigationTitle(isEditing ? "Edit Profile" : "Profile Info")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {

            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
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
                        Task {
                            profile.fields = tempProfile
                            await vm.saveProfile(profile)
                            if vm.errorMessage == nil {
                                isEditing = false
                                dismiss()
                            }
                        }
                    } else {
                        isEditing = true
                    }
                }
                .foregroundColor(Color("Warning"))
            }
        }
        .alert("Error", isPresented: Binding(
            get: { vm.errorMessage != nil },
            set: { if !$0 { vm.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
    }
}


