//
//  ProfileView.swift
//  MoviesApp
//

import SwiftUI

struct ProfileView: View {

    let userID: String

    /// Shared app-wide instance passed from the parent view.
    @ObservedObject var api: APIServices
    @StateObject private var vm: ProfileViewModel

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    init(userID: String, api: APIServices) {
        self.userID = userID
        self.api = api
        _vm = StateObject(wrappedValue: ProfileViewModel(api: api))
    }

    private var favoriteMovies: [MovieDTO] {
        api.movies.filter { api.favoriteMovieIDs.contains($0.id) }
    }

    var body: some View {
        // No inner NavigationStack: this screen is pushed
        // inside the app's existing navigation stack.
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
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

                    // MARK: - Saved Movies
                    if favoriteMovies.isEmpty {
                        VStack(spacing: 12) {
                            Spacer().frame(height: 60)

                            Image("Image")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 90, height: 90)

                            Text("No saved movies yet, start save your favourites")
                                .foregroundColor(.dark3)
                                .font(.footnote)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }

                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Saved Movies")
                                .font(.headline)
                                .bold()
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            LazyVGrid(columns: columns, spacing: 14) {
                                ForEach(favoriteMovies) { movie in
                                    NavigationLink {
                                        MovieDetailsView(movie: movie, api: api)
                                    } label: {
                                        PosterCard(
                                            urlString: movie.fields.poster,
                                            width: 165,
                                            height: 240
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal, 18)
                    }

                    Spacer(minLength: 30)
                }
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await vm.fetchProfiles()

            // Load favorites if the user landed here before they were fetched.
            if api.favoriteMovieIDs.isEmpty {
                try? await api.fetchFavorites(userID: userID)
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
