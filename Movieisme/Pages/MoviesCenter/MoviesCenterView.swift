//
//  MoviesCenterView.swift
//  MoviesApp
//
//

import SwiftUI

struct MoviesCenterView: View {

    @EnvironmentObject private var session: SessionManager

    @ObservedObject var api: APIServices
    @StateObject private var vm: MoviesCenterViewModel

    @State private var selectedHero = 0
    @State private var searchText = ""
    @State private var showGuestAlert = false

    init(api: APIServices) {
        self.api = api
        _vm = StateObject(wrappedValue: MoviesCenterViewModel(api: api))
    }

    private var currentUserID: String {
        session.currentUserID ?? ""
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {

                    header
                    searchBar

                    if vm.isLoading {
                        ProgressView()
                            .padding()
                            .scaleEffect(1.5)
                            .tint(.mainColor1)

                    } else {

                        Text("High Rated")
                            .font(.headline)
                            .bold()
                            .foregroundStyle(.white)

                        VStack(spacing: 10) {

                            TabView(selection: $selectedHero) {
                                ForEach(
                                    Array(
                                        vm.filteredMovies(search: searchText)
                                            .sorted { $0.fields.IMDb_rating > $1.fields.IMDb_rating }
                                            .prefix(5)
                                            .enumerated()
                                    ),
                                    id: \.offset
                                ) { idx, movie in

                                    NavigationLink {
                                        MovieDetailsView(
                                            movie: movie,
                                            api: api
                                        )
                                    } label: {
                                        TopMovieCard(movie: movie)
                                    }
                                    .buttonStyle(.plain)
                                    .tag(idx)
                                }
                            }
                            .frame(width: 350, height: 446)
                            .tabViewStyle(.page(indexDisplayMode: .never))

                            HStack(spacing: 6) {
                                let count = max(
                                    Array(
                                        vm.filteredMovies(search: searchText)
                                            .sorted { $0.fields.IMDb_rating > $1.fields.IMDb_rating }
                                            .prefix(5)
                                    ).count,
                                    1
                                )

                                ForEach(0..<count, id: \.self) { i in
                                    Circle()
                                        .frame(width: 6, height: 6)
                                        .foregroundStyle(.white.opacity(i == selectedHero ? 0.95 : 0.25))
                                }
                            }
                        }

                        categorySection(title: "Drama", items: vm.movies(forGenre: "Drama"))
                        categorySection(title: "Comedy", items: vm.movies(forGenre: "Comedy"))
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
        }
        .navigationBarBackButtonHidden(true)
        .task {
            await vm.fetchMovies()

            do {
                try await api.fetchProfiles()
            } catch {
                vm.errorMessage = error.localizedDescription
            }

            if session.isSignedIn {
                try? await api.fetchFavorites(userID: currentUserID)
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
        .alert("Sign in required", isPresented: $showGuestAlert) {
            Button("Sign in") { session.signOut() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Sign in to view your profile and save movies.")
        }
    }





    //  MARK: - Header
    private var header: some View {
        HStack {
            Text("Movies Center")
                .font(.title2)
                .bold()
                .foregroundStyle(.white)

            Spacer()

            if session.isSignedIn {
                NavigationLink {
                    ProfileView(userID: currentUserID, api: api)
                } label: {

                    if let user = api.getProfile(by: currentUserID) {
                        avatarView(
                            name: user.fields.name,
                            imageURL: user.fields.profile_image
                        )

                    } else if vm.isLoading {
                        Circle()
                            .fill(Color.dark2)
                            .frame(width: 41, height: 41)
                            .overlay {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(0.7)
                            }

                    } else {
                        Circle()
                            .fill(Color.dark2)
                            .frame(width: 41, height: 41)
                    }
                }
                .buttonStyle(.plain)

            } else {
                Button {
                    showGuestAlert = true
                } label: {
                    Circle()
                        .fill(Color.dark2)
                        .frame(width: 41, height: 41)
                        .overlay {
                            Image(systemName: "person.fill")
                                .foregroundStyle(.white.opacity(0.7))
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 8)
    }

    private func avatarView(name: String, imageURL: String?) -> some View {
        Group {
            if let imageURL,
               let url = URL(string: imageURL),
               !imageURL.isEmpty {

                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        Circle()
                            .fill(Color.dark2)
                            .overlay {
                                Text(name.prefix(1))
                                    .foregroundColor(.white)
                                    .font(.headline)
                                    .bold()
                            }
                    }
                }

            } else {
                Circle()
                    .fill(Color.dark2)
                    .overlay {
                        Text(name.prefix(1))
                            .foregroundColor(.white)
                            .font(.headline)
                            .bold()
                    }
            }
        }
        .frame(width: 41, height: 41)
        .clipShape(Circle())
    }





    //  MARK: -  SearchBar
    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.white.opacity(0.45))

            TextField("Search for Movie name , actors ...", text: $searchText)
                .font(.subheadline)
                .foregroundStyle(.white)
                .tint(.white)

            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.dark4)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 44)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }





    //  MARK: -  Category Section
    private func categorySection(title: String, items: [MovieDTO]) -> some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack {
                Text(title)
                    .font(.headline)
                    .bold()
                    .foregroundStyle(.white)

                Spacer()

                Text("Show more")
                    .font(.subheadline)
                    .foregroundStyle(.mainColor1)
                    .bold()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(items.prefix(10)) { movie in
                        NavigationLink {
                            MovieDetailsView(
                                movie: movie,
                                api: api
                            )
                        } label: {
                            PosterCard(urlString: movie.fields.poster)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(.top, 15)
    }
}





// MARK: -  TopMovieCard
private struct TopMovieCard: View {

    let movie: MovieDTO

    var body: some View {
        ZStack(alignment: .bottomLeading) {

            AsyncImage(url: URL(string: movie.fields.poster)) { phase in
                switch phase {
                case .success(let img):
                    img
                        .resizable()
                        .scaledToFill()
                        .frame(width: 340, height: 434)
                        .cornerRadius(8)

                default:
                    Rectangle().fill(.gray.opacity(0.2))
                        .frame(width: 340, height: 434)
                        .cornerRadius(8)
                }
            }
            .frame(width: 350, height: 434)

            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.35), Color.black.opacity(0.95)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 6) {
                Text(movie.fields.name)
                    .font(.title3)
                    .bold()
                    .foregroundStyle(.white)

                HStack(spacing: 4) {
                    Text(String(format: "%.1f", movie.fields.IMDb_rating / 2))
                        .font(.title2)
                        .foregroundStyle(.white)
                        .bold()

                    Text("Out of 5")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .bold()
                        .padding(.top, 5)
                }

                HStack(spacing: 4) {
                    ForEach(0..<5) { index in
                        Image(systemName: index < Int(movie.fields.IMDb_rating / 2) ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                }

                Text("\(movie.fields.genre.first ?? "") • \(movie.fields.runtime)")
                    .font(.footnote)
                    .foregroundStyle(.dark4)
            }
            .padding(16)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}





// MARK: - PosterCard
struct PosterCard: View {

    let urlString: String
    var width: CGFloat = 150
    var height: CGFloat = 220

    var body: some View {
        AsyncImage(url: URL(string: urlString)) { phase in
            switch phase {
            case .success(let img):
                img.resizable().scaledToFill()
            default:
                Rectangle().fill(.gray.opacity(0.2))
            }
        }
        .frame(width: width, height: height)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
