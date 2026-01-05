//
//  ProfileView.swift
//  MoviesApp
//
//  Created by Arwa Alkadi on 24/12/2025.
//
import SwiftUI

struct ProfileView: View {

    @StateObject private var api = APIServices()
    let userID = "recXYus6Hnq6ApTiu"

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 16) {
                if let record = api.getProfile(by: userID) {
                    profileCard(record: record)
                        .padding()
                } else if api.isLoading {
                    ProgressView()

                } else if let error = api.errorMessage {
                    Text(error)
                        .foregroundColor(.red)

                } else {
                    Text("No profile found")
                        .foregroundColor(.white.opacity(0.7))
                }
               
                    Spacer()

                    Image("Image") // من Assets
                        .resizable()
                        .scaledToFit()
                        .frame(width: 90, height: 90)
                       

                    Text("No saved movies yet, start save your favourites")
                        .foregroundColor(.dark3)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    
                    Spacer()
                }
            }
            .navigationTitle("Profile")
        }
        .task {
            await api.fetchProfiles()
        }
    }

    func binding(for record: ProfileDTO) -> Binding<ProfileDTO> {
        Binding {
            record
        } set: { updated in
            api.updateProfile(updated)
        }
    }

    @ViewBuilder
    func profileCard(record: ProfileDTO) -> some View {
        NavigationLink {
            EditProfileView(profile: binding(for: record))
        } label: {
            HStack(spacing: 15) {
                

                ZStack {
                                    Circle()
                                        .fill(Color.dark3)
                                        .frame(width: 78, height: 78)

                                    if let urlString = record.fields.profile_image,
                                       let url = URL(string: urlString),
                                       !urlString.isEmpty {

                                        AsyncImage(url: url) { phase in
                                            switch phase {
                                            case .success(let image):
                                                image.resizable().scaledToFill()
                                            default:
                                                Image(systemName: "person.fill").foregroundColor(.white)
                                            }
                                        }
                                        .frame(width: 78, height: 78)
                                        .clipShape(Circle())

                                    } else {
                                        Image(systemName: "person.fill")
                                            .foregroundColor(.white)
                                    }
                                
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text(record.fields.name)
                        .foregroundColor(.white)
                        .font(.headline)

                    Text(record.fields.email)
                        .foregroundColor(.gray)
                        .font(.subheadline)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.08))
            )
        }
        .buttonStyle(.plain)
    }
    
    
    }

    #Preview {
        ProfileView()
            .preferredColorScheme(.dark)
    }

