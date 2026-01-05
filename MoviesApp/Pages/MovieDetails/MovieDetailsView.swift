//
//  MovieDetailsView.swift
//  MoviesApp
//
//  Created by Arwa Alkadi on 24/12/2025.
//

import SwiftUI

// MARK: - MovieDetailsView
struct MovieDetailsView: View {

    let movie: MovieDTO
    @Environment(\.dismiss) var dismiss
    @StateObject var vm = MovieDetailsViewModel()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {

                // ----------------------------------------
                // Poster
                // ----------------------------------------
                moviePoster

                // ----------------------------------------
                // Content
                // ----------------------------------------
                VStack(alignment: .leading, spacing: 18) {

                    // Title
                    Text(movie.fields.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    // Info grid
                    infoGrid

                    // Story
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

                    // IMDb Rating
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

                   
                    // ----------------------------------------
                    // Director
                    // ----------------------------------------
                    sectionTitle("Director")

                    if vm.directors.isEmpty {
                        HStack(spacing: 12) {
                            starMini(name: "-", imageURL: nil)
                            Spacer()
                        }
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 18) {
                                ForEach(vm.directors) { d in
                                    starMini(name: d.fields.name, imageURL: d.fields.image)
                                }
                            }
                        }
                    }
                    
                    // ----------------------------------------
                    // Stars
                    // ----------------------------------------
                    sectionTitle("Stars")

                   

                    if vm.actors.isEmpty {
                        HStack(spacing: 18) {
                            starMini(name: "-", imageURL: nil)
                            starMini(name: "-", imageURL: nil)
                            starMini(name: "-", imageURL: nil)
                        }
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 18) {
                                ForEach(vm.actors) { a in
                                    starMini(name: a.fields.name, imageURL: a.fields.image)
                                }
                            }
                        }
                    }

                    Divider()
                        .frame(height: 1)
                        .overlay(Color.white.opacity(0.12))

                    // ----------------------------------------
                    // Reviews
                    // ----------------------------------------
                    VStack(alignment: .leading, spacing: 10) {

                        sectionTitle("Rating & Reviews")

                        if vm.isLoading {
                            ProgressView()
                                .padding()
                                .scaleEffect(1.5)
                                .tint(.mainColor1)

                        } else {

                            if vm.reviews.isEmpty {
                                Text("No reviews yet")
                                    .foregroundStyle(.dark4)
                                    .padding(.vertical, 10)

                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 14) {
                                        ForEach(vm.reviews) { r in

                                            reviewCard(
                                                userName: vm.userName(for: r.fields.user_id),
                                                userImageURL: vm.userImage(for: r.fields.user_id),
                                                text: r.fields.review_text,
                                                day: r.createdTime,
                                                rating: r.fields.rate,
                                                onDelete: {
                                                    Task { _ = await vm.deleteReview(reviewID: r.id) }
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
                Button { dismiss() } label: {
                    circleIcon("chevron.left")
                }
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
                       //باقي
                    } label: {
                        circleIcon("bookmark")
                    }
                }
            }
            .sharedBackgroundVisibility(.hidden)
        }
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            await vm.fetchReviews(movieID: movie.id) // ✅ يجلب الريفيو + اليوزرز تلقائياً
            await vm.fetchActors(movieID: movie.id)
            await vm.fetchDirectors(movieID: movie.id)  
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



    // ----------------------------------------
    // Movie Poster
    // ----------------------------------------
    var moviePoster: some View {
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


    // ----------------------------------------
    // Info Grid
    // ----------------------------------------
    var infoGrid: some View {
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


    // ----------------------------------------
    // Add Review Button
    // ----------------------------------------
    var bottomButton: some View {
        NavigationLink {
            AddReviewView(movieID: movie.id) {
                Task { await vm.fetchReviews(movieID: movie.id) }
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


    // ----------------------------------------
    // Helpers
    // ----------------------------------------
    func initials(from name: String) -> String {
        let parts = name.split(separator: " ")
        let first = parts.first?.first.map(String.init) ?? ""
        let last  = parts.dropFirst().first?.first.map(String.init) ?? ""
        return (first + last).uppercased()
    }

    // صورة + fallback (initials)
    func starMini(name: String, imageURL: String?) -> some View {
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
    func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.headline)
            .fontWeight(.bold)
            .foregroundStyle(.white)
    }

    func infoItem(_ title: String, _ value: String) -> some View {
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

    func circleIcon(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.mainColor1)
            .frame(width: 36, height: 36)
            .background(Color.black.opacity(0.35))
            .clipShape(Circle())
    }

    func avatar(_ initials: String) -> some View {
        Text(initials)
            .font(.headline)
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .frame(width: 76, height: 76)
            .background(Color.white.opacity(0.12))
            .clipShape(Circle())
    }

    func starMini(_ name: String, _ initials: String) -> some View {
        VStack(spacing: 8) {
            avatar(initials)

            Text(name)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.dark4)
        }
    }

    func starsRow(_ rating: Int) -> some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { i in
                Image(systemName: i <= rating ? "star.fill" : "star")
                    .foregroundStyle(.mainColor1.opacity(i <= rating ? 1 : 0.35))
                    .font(.caption)
                    .fontWeight(.semibold)
            }
        }
    }

    func dateOnly(_ isoString: String) -> String {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let date = iso.date(from: isoString) else { return isoString }

        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"   // تقدرين تغيرينها: "dd/MM/yyyy"
        return f.string(from: date)
    }
    
    // ✅ Review Card with user image + name
    func reviewCard(
        userName: String,
        userImageURL: String?,
        text: String,
        day: String,
        rating: Int,
        onDelete: @escaping () -> Void
    ) -> some View {

        VStack(alignment: .leading, spacing: 12) {

            HStack(spacing: 10) {

                // User Image
                Group {
                    if let urlString = userImageURL, let url = URL(string: urlString) {
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
    let onDone: () -> Void

    @Environment(\.dismiss) var dismiss
    @StateObject var vm = MovieDetailsViewModel()

    @State var reviewText: String = ""
    @State var rating: Int = 5

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

                    // TextEditor (Gray Box without border)
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

                    // Rating
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
                            let text = reviewText.trimmingCharacters(in: .whitespacesAndNewlines)

                            let ok = await vm.createReview(
                                movieID: movieID,
                                text: text,
                                rate: rating
                            )

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












// MARK: - Preview
#Preview {
    NavigationStack {
        MovieDetailsView(
            movie: MovieDTO(
                id: "recfNj1e4waOUJLxd",
                createdTime: "2025-01-06T08:55:18.000Z",
                fields: MovieFields(
                    name: "The Shawshank Redemption",
                    poster: "https://i.pinimg.com/736x/c6/7e/87/c67e879868febbf0941a6cdde645f179.jpg",
                    story: "Chronicles the experiences of a formerly successful banker as a prisoner in the gloomy jailhouse of Shawshank.",
                    runtime: "2h 22m",
                    genre: ["Drama"],
                    rating: "R",
                    IMDb_rating: 9.3,
                    language: ["English"]
                )
            )
        )
    }
}
