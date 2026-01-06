//
//  MovieDetailsView.swift
//  MoviesApp
//
//

import SwiftUI

// MARK: - MovieDetailsView
struct MovieDetailsView: View {

    let movie: MovieDTO
    @ObservedObject var api: APIServices
    let currentUserID: String

    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm: MovieDetailsViewModel

    init(movie: MovieDTO, api: APIServices, currentUserID: String) {
        self.movie = movie
        self.api = api
        self.currentUserID = currentUserID
        _vm = StateObject(wrappedValue: MovieDetailsViewModel(api: api, currentUserID: currentUserID))
    }

    /// Read from unified cache
    private var reviews: [ReviewDTO] {
        api.reviewsByMovieID[movie.id] ?? []
    }

    private var actors: [ActorsDTO] {
        api.actorsByMovieID[movie.id] ?? []
    }

    private var directors: [DirectorsDTO] {
        api.directorsByMovieID[movie.id] ?? []
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {

                moviePoster

                VStack(alignment: .leading, spacing: 18) {

                    Text(movie.fields.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    infoGrid

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Story")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)

                        Text(movie.fields.story)
                            .font(.subheadline)
                            .foregroundStyle(.dark4)
                            .lineSpacing(4)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        sectionTitle("IMDb Rating")
                        Text("\(String(format: "%.1f", movie.fields.IMDb_rating)) / 10")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.dark4)
                    }

                    Divider()
                        .frame(height: 1)
                        .overlay(Color.white.opacity(0.12))

                    // Director
                    sectionTitle("Director")
                    if directors.isEmpty {
                        HStack(spacing: 12) { starMini(name: "-", imageURL: nil); Spacer() }
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 18) {
                                ForEach(directors) { d in
                                    starMini(name: d.fields.name, imageURL: d.fields.image)
                                }
                            }
                        }
                    }

                    /// Stars
                    sectionTitle("Stars")
                    if actors.isEmpty {
                        HStack(spacing: 18) {
                            starMini(name: "-", imageURL: nil)
                            starMini(name: "-", imageURL: nil)
                            starMini(name: "-", imageURL: nil)
                        }
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 18) {
                                ForEach(actors) { a in
                                    starMini(name: a.fields.name, imageURL: a.fields.image)
                                }
                            }
                        }
                    }

                    Divider()
                        .frame(height: 1)
                        .overlay(Color.white.opacity(0.12))

                    /// Reviews
                    VStack(alignment: .leading, spacing: 10) {

                        sectionTitle("Rating & Reviews")

                        if vm.isLoading {
                            ProgressView()
                                .padding()
                                .scaleEffect(1.5)
                                .tint(.mainColor1)
                        } else {

                            if reviews.isEmpty {
                                Text("No reviews yet")
                                    .foregroundStyle(.dark4)
                                    .padding(.vertical, 10)
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 14) {
                                        ForEach(reviews) { r in
                                            reviewCard(
                                                userName: api.userName(for: r.fields.user_id),
                                                userImageURL: api.userImageURL(for: r.fields.user_id),
                                                text: r.fields.review_text,
                                                day: r.createdTime,
                                                rating: r.fields.rate,
                                                onDelete: {
                                                    Task { await vm.deleteReview(movieID: movie.id, reviewID: r.id) }
                                                }
                                            )
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }

                            bottomButton
                        }
                    }
                }
                .frame(width: 360, alignment: .leading)
                .padding(.horizontal, 18)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 30)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle(movie.fields.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {

            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: { circleIcon("chevron.left") }
            }
            .sharedBackgroundVisibility(.hidden)

            ToolbarItemGroup(placement: .topBarTrailing) {
                HStack(spacing: 0) {

                    ShareLink(
                        item: movie.fields.name,
                        subject: Text(movie.fields.name),
                        message: Text(movie.fields.story)
                    ) {
                        circleIcon("square.and.arrow.up")
                    }

                    Button {
                        /// TODO
                    } label: {
                        circleIcon("bookmark")
                    }
                }
            }
            .sharedBackgroundVisibility(.hidden)
        }
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            await vm.load(movieID: movie.id)
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

    
    
    
        
    // MARK: - Poster
    private var moviePoster: some View {
        ZStack {
            AsyncImage(url: URL(string: movie.fields.poster)) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().scaledToFill()
                default:
                    Rectangle().fill(.gray.opacity(0.2))
                }
            }
            .frame(width: 400, height: 500)
            .clipped()

            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.50), Color.black],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    
    
    
    
    // MARK: - Info Grid
    private var infoGrid: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 12) {
                infoItem("Duration", movie.fields.runtime)
                infoItem("Genre", movie.fields.genre.joined(separator: ", "))
            }

            Spacer()

            VStack(alignment: .leading, spacing: 12) {
                infoItem("Language", movie.fields.language.joined(separator: ", "))
                infoItem("Age", movie.fields.rating)
            }
        }
    }

    
    
    
    
    // MARK: - Add Review Button
    private var bottomButton: some View {
        NavigationLink {
            AddReviewView(
                movieID: movie.id,
                api: api,
                currentUserID: currentUserID
            ) {
                Task { await vm.refreshReviews(movieID: movie.id) }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 14, weight: .semibold))

                Text("Write a review")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(Color.mainColor1)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.mainColor1, lineWidth: 1.2)
            )
        }
        .buttonStyle(.plain)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.9))
    }

    
    
    
    
    // MARK: - Helpers UI
    private func initials(from name: String) -> String {
        let parts = name.split(separator: " ")
        let first = parts.first?.first.map(String.init) ?? ""
        let last  = parts.dropFirst().first?.first.map(String.init) ?? ""
        return (first + last).uppercased()
    }

    private func starMini(name: String, imageURL: String?) -> some View {
        VStack(spacing: 8) {

            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 76, height: 76)

                if let imageURL, let url = URL(string: imageURL), !imageURL.isEmpty {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable().scaledToFill()
                        default:
                            Text(initials(from: name))
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(width: 76, height: 76)
                    .clipShape(Circle())
                } else {
                    Text(initials(from: name))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
            }

            Text(name)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.dark4)
                .lineLimit(1)
                .frame(width: 90)
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.headline)
            .fontWeight(.bold)
            .foregroundStyle(.white)
    }

    private func infoItem(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)

            Text(value)
                .font(.footnote)
                .foregroundStyle(.dark4)
        }
    }

    private func circleIcon(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.mainColor1)
            .frame(width: 36, height: 36)
            .background(Color.black.opacity(0.35))
            .clipShape(Circle())
    }

    private func starsRow(_ rating: Int) -> some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { i in
                Image(systemName: i <= rating ? "star.fill" : "star")
                    .foregroundStyle(.mainColor1.opacity(i <= rating ? 1 : 0.35))
                    .font(.caption)
                    .fontWeight(.semibold)
            }
        }
    }

    private func dateOnly(_ isoString: String) -> String {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = iso.date(from: isoString) else { return isoString }

        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    private func reviewCard(
        userName: String,
        userImageURL: String?,
        text: String,
        day: String,
        rating: Int,
        onDelete: @escaping () -> Void
    ) -> some View {

        VStack(alignment: .leading, spacing: 12) {

            HStack(spacing: 10) {

                Group {
                    if let urlString = userImageURL,
                       let url = URL(string: urlString),
                       !urlString.isEmpty {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let img):
                                img.resizable().scaledToFill()
                            default:
                                Circle().fill(Color.white.opacity(0.12))
                            }
                        }
                    } else {
                        Circle().fill(Color.white.opacity(0.12))
                    }
                }
                .frame(width: 42, height: 42)
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(userName.isEmpty ? "User" : userName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)

                    starsRow(rating)
                }

                Spacer()
            }

            Text(text)
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.75))
                .lineSpacing(3)

            Spacer()

            HStack {
                Spacer()
                Text(dateOnly(day))
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .padding(14)
        .frame(width: 305, height: 188)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .contextMenu {
            Button(role: .destructive) { onDelete() } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}









// MARK: - AddReviewView
struct AddReviewView: View {

    let movieID: String
    @ObservedObject var api: APIServices
    let currentUserID: String
    let onDone: () -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm: MovieDetailsViewModel

    @State private var reviewText: String = ""
    @State private var rating: Int = 5

    init(movieID: String, api: APIServices, currentUserID: String, onDone: @escaping () -> Void) {
        self.movieID = movieID
        self.api = api
        self.currentUserID = currentUserID
        self.onDone = onDone
        _vm = StateObject(wrappedValue: MovieDetailsViewModel(api: api, currentUserID: currentUserID))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 18) {

                    HStack {
                        Text("Review")
                            .font(.body)
                            .foregroundColor(.dark4)
                            .bold()
                        Spacer()
                    }
                    .padding(.top, 10)

                    TextEditor(text: $reviewText)
                        .scrollContentBackground(.hidden)
                        .foregroundStyle(.white)
                        .padding(12)
                        .frame(width: 360, height: 150)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.gray.opacity(0.25))
                        )
                        .padding(.horizontal, 18)

                    HStack {
                        Text("Rating")
                            .font(.body)
                            .foregroundColor(.dark4)
                            .bold()

                        Spacer()

                        HStack(spacing: 6) {
                            ForEach(1...5, id: \.self) { i in
                                Image(systemName: i <= rating ? "star.fill" : "star")
                                    .foregroundStyle(.mainColor1.opacity(i <= rating ? 1 : 0.35))
                                    .font(.body)
                                    .fontWeight(.semibold)
                                    .onTapGesture { rating = i }
                            }
                        }
                    }
                    .padding(.horizontal, 22)

                    Spacer()
                }
                .frame(width: 360)
                .padding(.bottom, 30)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .toolbar {

                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        HStack {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.mainColor1)
                                .bold()
                            Text("Back")
                                .foregroundColor(.mainColor1)
                        }
                    }
                }
                .sharedBackgroundVisibility(.hidden)

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            let ok = await vm.addReview(movieID: movieID, text: reviewText, rate: rating)
                            if ok {
                                onDone()
                                dismiss()
                            }
                        }
                    } label: {
                        Text("Add")
                            .foregroundColor(.mainColor1)
                            .bold()
                    }
                    .disabled(reviewText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .sharedBackgroundVisibility(.hidden)
            }
        }
        .navigationBarBackButtonHidden(true)
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
