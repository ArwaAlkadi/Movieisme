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
    
    var body: some View {
        VStack(spacing: 20) {
            
            // Avatar
            ZStack {

                Color.black.ignoresSafeArea()
                
                Circle()
                    .fill(Color.dark3)
                    .frame(width: 78, height: 78)

                if let urlString = profile.fields.profile_image,
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
                    .frame(width: 78, height: 78)
                    .clipShape(Circle())

                } else {
                    Image(systemName: "person.fill")
                        .foregroundColor(.white)
                }

                if isEditing {
                    Circle()
                        .fill(Color.black.opacity(0.6))
                        .frame(width: 78, height: 78)

                    Image(systemName: "camera.fill")
                        .foregroundColor(Color("Warning"))
                        .font(.system(size: 20))
                        .onTapGesture {
                            print("Camera tapped")
                        }
                }
            }
            
            Form {
                HStack {
                    Text("First Name")
                        .foregroundColor(.white)
                        .frame(width: 90, alignment: .leading)
                    
                    TextField("", text: Binding(
                        get: { profile.fields.firstName },
                        set: { newFirst in
                            profile.fields.name = newFirst + " " + profile.fields.lastName
                        }
                    ))
                    .foregroundColor(.white)
                    .textFieldStyle(.plain)
                    .disabled(!isEditing)
                }
                
                HStack {
                    Text("Last Name")
                        .foregroundColor(.white)
                        .frame(width: 90, alignment: .leading)
                    
                    TextField("", text: Binding(
                        get: { profile.fields.lastName },
                        set: { newLast in
                            profile.fields.name = profile.fields.firstName + " " + newLast
                        }
                    ))
                    .foregroundColor(.white)
                    .textFieldStyle(.plain)
                    .disabled(!isEditing)
                }
            }
        }
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
                    isEditing.toggle()
                }
                .foregroundColor(Color("Warning"))
            }
        }
    }
}
