//
//  ProfileView.swift
//  MoviesApp
//
//

import SwiftUI

struct ProfileView: View {

    let userID: String

    @StateObject private var api: APIServices
    @StateObject private var vm: ProfileViewModel

    init(userID: String, api: APIServices) {
        self.userID = userID
        _api = StateObject(wrappedValue: api)
        _vm  = StateObject(wrappedValue: ProfileViewModel(api: api))
    }

    init(userID: String) {
        self.userID = userID
        let api = APIServices()
        _api = StateObject(wrappedValue: api)
        _vm  = StateObject(wrappedValue: ProfileViewModel(api: api))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 16) {

                    if let record = vm.getProfile(by: userID) {
                        profileCard(record: record)
                            .padding()

                    } else if vm.isLoading {
                        ProgressView()

                    } else if let error = vm.errorMessage {
                        Text(error).foregroundColor(.red)

                    } else {
                        Text("No profile found")
                            .foregroundColor(.white.opacity(0.7))
                    }

                    Spacer()

                    Image("Image")
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
            await vm.fetchProfiles()
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

    @ViewBuilder
    private func profileCard(record: ProfileDTO) -> some View {
        NavigationLink {
            EditProfileView(
                vm: vm,
                profile: vm.binding(for: record.id)
            )
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
                Image(systemName: "chevron.right").foregroundColor(.gray)
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
