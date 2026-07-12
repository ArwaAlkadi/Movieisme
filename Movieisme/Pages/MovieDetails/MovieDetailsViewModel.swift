//
//  MovieDetailsViewModel.swift
//  MoviesApp
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class MovieDetailsViewModel: ObservableObject {

    @Published var isLoading = false
    @Published var errorMessage: String?

    private let api: APIServices

    init(api: APIServices) {
        self.api = api
    }

    /// Loads reviews, actors, and directors in parallel.
    func load(movieID: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let r: Void = api.fetchReviews(movieID: movieID)
            async let a: Void = api.fetchActors(movieID: movieID)
            async let d: Void = api.fetchDirectors(movieID: movieID)
            _ = try await (r, a, d)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshReviews(movieID: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await api.fetchReviews(movieID: movieID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// The user ID comes from the session at call time instead of
    /// being stored, so the view model stays session-agnostic.
    func addReview(movieID: String, text: String, rate: Int, userID: String) async -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !userID.isEmpty else { return false }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await api.createReview(movieID: movieID, text: trimmed, rate: rate, userID: userID)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func deleteReview(movieID: String, reviewID: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await api.deleteReview(reviewID: reviewID, movieID: movieID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
