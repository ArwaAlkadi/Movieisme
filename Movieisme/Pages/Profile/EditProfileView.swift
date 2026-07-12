//
//   EditProfileView.swift
//  MoviesApp
//
//

import SwiftUI
import PhotosUI
import Foundation

struct EditProfileView: View {

    @ObservedObject var vm: ProfileViewModel
    @Binding var profile: ProfileDTO

    @EnvironmentObject private var session: SessionManager
    @EnvironmentObject private var api: APIServices
    @Environment(\.dismiss) private var dismiss

    @State private var isEditing = false
    @State private var tempProfile: ProfileFields

    @State private var pickedItem: PhotosPickerItem?

    init(vm: ProfileViewModel, profile: Binding<ProfileDTO>) {
        self.vm = vm
        self._profile = profile
        self._tempProfile = State(initialValue: profile.wrappedValue.fields)
    }

    var body: some View {
        VStack(spacing: 30) {

            // MARK: -  Avatar
            PhotosPicker(
                selection: $pickedItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                avatar
            }
            .disabled(!isEditing)
            .padding(.top, 20)
            .onChange(of: pickedItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let dataURL = Self.makeAvatarDataURL(from: data) {
                        tempProfile.profile_image = dataURL
                    }
                }
            }

            // MARK: -  Fields
            VStack(spacing: 0) {

                HStack {
                    Text("First Name")
                        .foregroundColor(.white)
                        .frame(width: 100, alignment: .leading)

                    TextField("", text: Binding(
                        get: { tempProfile.firstName },
                        set: { newFirst in
                            let last = tempProfile.lastName
                            tempProfile.name = last.isEmpty
                                ? newFirst
                                : newFirst + " " + last
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
                            let first = tempProfile.firstName
                            tempProfile.name = newLast.isEmpty
                                ? first
                                : first + " " + newLast
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
                Button {
                    api.clearSessionData()
                    session.signOut()
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
                Button {
                    if isEditing {
                        /// إلغاء التعديل: نرجع القيم الأصلية
                        tempProfile = profile.fields
                        isEditing = false
                    } else {
                        dismiss()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text(isEditing ? "Cancel" : "Back")
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


    // MARK: - Avatar View
    private var avatar: some View {
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
    }


    
    private static func makeAvatarDataURL(from data: Data) -> String? {
        guard let ui = UIImage(data: data) else { return nil }

        let target: CGFloat = 300
        let scale = min(target / ui.size.width, target / ui.size.height, 1)
        let newSize = CGSize(
            width: ui.size.width * scale,
            height: ui.size.height * scale
        )

        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in
            ui.draw(in: CGRect(origin: .zero, size: newSize))
        }

        guard let jpeg = resized.jpegData(compressionQuality: 0.5) else { return nil }
        return "data:image/jpeg;base64," + jpeg.base64EncodedString()
    }
}
