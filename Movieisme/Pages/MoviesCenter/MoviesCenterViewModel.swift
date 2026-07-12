//
//  MoviesCenterViewModel.swift
//  MoviesApp
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class MoviesCenterViewModel: ObservableObject {

    @Published var isLoading = false
    @Published var errorMessage: String?

    private let api: APIServices

    init(api: APIServices) {
        self.api = api
    }

    var movies: [MovieDTO] { api.movies }

    func fetchMovies() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await api.fetchMovies()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Helpers

    func filteredMovies(search: String) -> [MovieDTO] {
        let q = search.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return movies }
        return movies.filter { $0.fields.name.localizedCaseInsensitiveContains(q) }
    }

    func movies(forGenre genre: String) -> [MovieDTO] {
        movies.filter { $0.fields.genre.contains(genre) }
    }
}
