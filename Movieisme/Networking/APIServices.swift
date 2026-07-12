//
//  APIServices.swift
//  MoviesApp
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class APIServices: ObservableObject {

    // ========================================
    // MARK: - Published Properties
    // ========================================

    @Published var movies: [MovieDTO] = []
    @Published var profiles: [ProfileDTO] = []
    @Published var reviewsByMovieID: [String: [ReviewDTO]] = [:]
    @Published var actorsByMovieID: [String: [ActorsDTO]] = [:]
    @Published var directorsByMovieID: [String: [DirectorsDTO]] = [:]
    @Published var usersByID: [String: UserDTO] = [:]
    @Published var errorMessage: String?

    /// Movie IDs saved by the current user.
    @Published var favoriteMovieIDs: Set<String> = []

    /// The user's favorites record in Airtable (one record per user).
    private var favoriteRecordID: String?



    // ========================================
    // MARK: - API Configuration
    // ========================================

    // Credentials are loaded from Secrets.plist (not hardcoded).
    private var baseURL: String {
        "https://api.airtable.com/v0/\(Secrets.airtableBaseID)"
    }
    private var token: String {
        "Bearer \(Secrets.airtableToken)"
    }



    // ========================================
    // MARK: - Network: Request Builder
    // ========================================

    /// Builds a URLRequest with auth headers and an optional JSON body.
    private func request(
        _ path: String,
        method: String = "GET",
        body: Data? = nil
    ) throws -> URLRequest {

        guard let url = URL(string: "\(baseURL)/\(path)") else {
            throw URLError(.badURL)
        }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue(token, forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = body
        }

        return req
    }



    // ========================================
    // MARK: - Network: Response Validation
    // ========================================

    private struct AirtableErrorResponse: Decodable {
        struct Err: Decodable {
            let type: String
            let message: String
        }
        let error: Err
    }

    /// Throws a readable error when the HTTP status is not 2xx.
    private func validateWithBody(
        _ response: URLResponse,
        data: Data
    ) throws {

        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200...299).contains(http.statusCode) else {

            if let decoded = try? JSONDecoder()
                .decode(AirtableErrorResponse.self, from: data) {

                throw NSError(
                    domain: "Airtable",
                    code: http.statusCode,
                    userInfo: [
                        NSLocalizedDescriptionKey:
                        "\(decoded.error.type): \(decoded.error.message)"
                    ]
                )
            }

            throw NSError(
                domain: "HTTP",
                code: http.statusCode,
                userInfo: [
                    NSLocalizedDescriptionKey: "HTTP \(http.statusCode)"
                ]
            )
        }
    }



    // ========================================
    // MARK: - Network: Movies
    // ========================================

    /// Fetches all movies from Airtable.
    func fetchMovies() async throws {
        errorMessage = nil

        do {
            let req = try request("movies")
            let (data, resp) = try await URLSession.shared.data(for: req)
            try validateWithBody(resp, data: data)

            let decoded = try JSONDecoder()
                .decode(AirtableListResponse<MovieFields>.self, from: data)

            movies = decoded.records.map {
                MovieDTO(
                    id: $0.id,
                    createdTime: $0.createdTime,
                    fields: $0.fields
                )
            }
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }



    // ========================================
    // MARK: - Network: Profiles
    // ========================================

    /// Fetches all user profiles from Airtable.
    func fetchProfiles() async throws {
        errorMessage = nil

        do {
            let req = try request("users")
            let (data, resp) = try await URLSession.shared.data(for: req)
            try validateWithBody(resp, data: data)

            let decoded = try JSONDecoder()
                .decode(AirtableListResponse<ProfileFields>.self, from: data)

            profiles = decoded.records.map {
                ProfileDTO(
                    id: $0.id,
                    createdTime: $0.createdTime,
                    fields: $0.fields
                )
            }
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    /// Fetches users once and caches them (used by review cards).
    func fetchUsersIfNeeded() async throws {
        if !usersByID.isEmpty { return }
        errorMessage = nil

        do {
            let req = try request("users")
            let (data, resp) = try await URLSession.shared.data(for: req)
            try validateWithBody(resp, data: data)

            let decoded = try JSONDecoder()
                .decode(AirtableListResponse<UserFields>.self, from: data)

            let users = decoded.records.map {
                UserDTO(
                    id: $0.id,
                    createdTime: $0.createdTime,
                    fields: $0.fields
                )
            }

            usersByID = Dictionary(
                uniqueKeysWithValues: users.map { ($0.id, $0) }
            )
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    /// Saves profile changes to Airtable (PATCH).
    func saveProfileToAPI(_ profile: ProfileDTO) async throws {
        errorMessage = nil

        do {
            let dto = ProfileUpdateDTO(
                fields: .init(
                    name: profile.fields.name,
                    profile_image: profile.fields.profile_image
                )
            )

            let body = try JSONEncoder().encode(dto)
            let req = try request(
                "users/\(profile.id)",
                method: "PATCH",
                body: body
            )

            let (data, resp) = try await URLSession.shared.data(for: req)
            try validateWithBody(resp, data: data)

            updateProfileLocal(profile)

            // Keep the cached user in sync so review cards show fresh data.
            if usersByID[profile.id] != nil {
                usersByID[profile.id] = UserDTO(
                    id: profile.id,
                    createdTime: profile.createdTime,
                    fields: .init(
                        name: profile.fields.name,
                        profile_image: profile.fields.profile_image
                    )
                )
            }
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }



    // ========================================
    // MARK: - Network: Reviews
    // ========================================

    /// Fetches all reviews for a movie, newest first.
    func fetchReviews(movieID: String) async throws {
        errorMessage = nil

        do {
            let formula = "{movie_id}='\(movieID)'"
            let path = "reviews?filterByFormula=\(enc(formula))"

            let req = try request(path)
            let (data, resp) = try await URLSession.shared.data(for: req)
            try validateWithBody(resp, data: data)

            let decoded = try JSONDecoder()
                .decode(AirtableListResponse<ReviewFields>.self, from: data)

            // ISO8601 strings sort correctly as plain strings.
            reviewsByMovieID[movieID] = decoded.records
                .map {
                    ReviewDTO(
                        id: $0.id,
                        createdTime: $0.createdTime,
                        fields: $0.fields
                    )
                }
                .sorted { $0.createdTime > $1.createdTime }

            try await fetchUsersIfNeeded()
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    /// Creates a new review (POST) then refreshes the list.
    func createReview(
        movieID: String,
        text: String,
        rate: Int,
        userID: String
    ) async throws {

        errorMessage = nil

        do {
            let dto = ReviewCreateDTO(
                fields: .init(
                    review_text: text,
                    rate: rate,
                    movie_id: movieID,
                    user_id: userID
                )
            )

            let body = try JSONEncoder().encode(dto)
            let req = try request("reviews", method: "POST", body: body)

            let (data, resp) = try await URLSession.shared.data(for: req)
            try validateWithBody(resp, data: data)

            try await fetchReviews(movieID: movieID)
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    /// Deletes a review (DELETE) then refreshes the list.
    func deleteReview(
        reviewID: String,
        movieID: String
    ) async throws {

        errorMessage = nil

        do {
            let req = try request("reviews/\(reviewID)", method: "DELETE")
            let (data, resp) = try await URLSession.shared.data(for: req)
            try validateWithBody(resp, data: data)

            try await fetchReviews(movieID: movieID)
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }



    // ========================================
    // MARK: - Network: Favorites
    // ========================================

    /// Loads the user's favorites record (one record per user
    /// containing an array of movie IDs).
    func fetchFavorites(userID: String) async throws {
        errorMessage = nil

        do {
            let formula = "{user_id}='\(userID)'"
            let path = "favorites?filterByFormula=\(enc(formula))"

            let req = try request(path)
            let (data, resp) = try await URLSession.shared.data(for: req)
            try validateWithBody(resp, data: data)

            let decoded = try JSONDecoder()
                .decode(AirtableListResponse<FavoriteFields>.self, from: data)

            if let record = decoded.records.first {
                favoriteRecordID = record.id
                favoriteMovieIDs = Set(record.fields.movie_id ?? [])
            } else {
                favoriteRecordID = nil
                favoriteMovieIDs = []
            }
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    /// Adds or removes a movie from favorites.
    /// Updates the UI optimistically and rolls back on failure.
    func toggleFavorite(movieID: String, userID: String) async throws {
        errorMessage = nil

        var newIDs = favoriteMovieIDs
        if newIDs.contains(movieID) {
            newIDs.remove(movieID)
        } else {
            newIDs.insert(movieID)
        }
        let oldIDs = favoriteMovieIDs
        favoriteMovieIDs = newIDs

        do {
            if let recordID = favoriteRecordID {
                // Existing record: PATCH the movie ID array.
                let dto = FavoriteUpdateDTO(fields: .init(movie_id: Array(newIDs)))
                let body = try JSONEncoder().encode(dto)
                let req = try request("favorites/\(recordID)", method: "PATCH", body: body)

                let (data, resp) = try await URLSession.shared.data(for: req)
                try validateWithBody(resp, data: data)

            } else {
                // First favorite: POST a new record and remember its ID.
                let dto = FavoriteCreateDTO(
                    fields: .init(user_id: userID, movie_id: Array(newIDs))
                )
                let body = try JSONEncoder().encode(dto)
                let req = try request("favorites", method: "POST", body: body)

                let (data, resp) = try await URLSession.shared.data(for: req)
                try validateWithBody(resp, data: data)

                let created = try JSONDecoder()
                    .decode(AirtableSingleResponse<FavoriteFields>.self, from: data)
                favoriteRecordID = created.id
            }
        } catch {
            // Request failed: restore the previous state.
            favoriteMovieIDs = oldIDs
            errorMessage = error.localizedDescription
            throw error
        }
    }

    func isFavorite(_ movieID: String) -> Bool {
        favoriteMovieIDs.contains(movieID)
    }

    /// Called on sign-out to clear user-specific data.
    func clearSessionData() {
        favoriteMovieIDs = []
        favoriteRecordID = nil
    }



    // ========================================
    // MARK: - Network: Actors
    // ========================================

    /// Fetches all actors for a movie via the movie_actors link table.
    func fetchActors(movieID: String) async throws {
        errorMessage = nil

        do {
            let formula = "{movie_id}='\(movieID)'"
            let linkPath = "movie_actors?filterByFormula=\(enc(formula))"

            let linkReq = try request(linkPath)
            let (linkData, linkResp) = try await URLSession.shared.data(for: linkReq)
            try validateWithBody(linkResp, data: linkData)

            let linkDecoded = try JSONDecoder()
                .decode(AirtableListResponse<MovieActorFields>.self, from: linkData)

            let actorIDs = linkDecoded.records.map { $0.fields.actor_id }

            guard !actorIDs.isEmpty else {
                actorsByMovieID[movieID] = []
                return
            }

            let orParts = actorIDs.map {
                "RECORD_ID()='\($0)'"
            }.joined(separator: ",")

            let actorsPath =
                "actors?filterByFormula=\(enc("OR(\(orParts))"))"

            let actorsReq = try request(actorsPath)
            let (actorsData, actorsResp) =
                try await URLSession.shared.data(for: actorsReq)

            try validateWithBody(actorsResp, data: actorsData)

            let actorsDecoded = try JSONDecoder()
                .decode(AirtableListResponse<ActorsFields>.self, from: actorsData)

            actorsByMovieID[movieID] = actorsDecoded.records.map {
                ActorsDTO(
                    id: $0.id,
                    createdTime: $0.createdTime,
                    fields: $0.fields
                )
            }
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }



    // ========================================
    // MARK: - Network: Directors
    // ========================================

    /// Fetches all directors for a movie via the movie_directors link table.
    func fetchDirectors(movieID: String) async throws {
        errorMessage = nil

        do {
            let formula = "{movie_id}='\(movieID)'"
            let linkPath =
                "movie_directors?filterByFormula=\(enc(formula))"

            let linkReq = try request(linkPath)
            let (linkData, linkResp) =
                try await URLSession.shared.data(for: linkReq)

            try validateWithBody(linkResp, data: linkData)

            let linkDecoded = try JSONDecoder()
                .decode(AirtableListResponse<MovieDirectorFields>.self, from: linkData)

            let directorIDs = linkDecoded.records.map {
                $0.fields.director_id
            }

            guard !directorIDs.isEmpty else {
                directorsByMovieID[movieID] = []
                return
            }

            let orParts = directorIDs.map {
                "RECORD_ID()='\($0)'"
            }.joined(separator: ",")

            let directorsPath =
                "directors?filterByFormula=\(enc("OR(\(orParts))"))"

            let directorsReq = try request(directorsPath)
            let (directorsData, directorsResp) =
                try await URLSession.shared.data(for: directorsReq)

            try validateWithBody(directorsResp, data: directorsData)

            let directorsDecoded = try JSONDecoder()
                .decode(AirtableListResponse<DirectorsFields>.self, from: directorsData)

            directorsByMovieID[movieID] = directorsDecoded.records.map {
                DirectorsDTO(
                    id: $0.id,
                    createdTime: $0.createdTime,
                    fields: $0.fields
                )
            }
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }



    // ========================================
    // MARK: - Helpers: Local Operations (No Network)
    // ========================================

    /// Returns a profile by ID from the local cache.
    func getProfile(by id: String) -> ProfileDTO? {
        profiles.first { $0.id == id }
    }

    /// Returns a profile by email from the local cache.
    func getProfileByEmail(_ email: String) -> ProfileDTO? {
        profiles.first { $0.fields.email == email }
    }

    /// Updates a profile in the local cache only.
    func updateProfileLocal(_ updated: ProfileDTO) {
        if let idx = profiles.firstIndex(where: { $0.id == updated.id }) {
            profiles[idx] = updated
        }
    }

    /// Returns a user name from the cache, or "User" if not found.
    func userName(for userID: String) -> String {
        usersByID[userID]?.fields.name ?? "User"
    }

    /// Returns a user image URL from the cache.
    func userImageURL(for userID: String) -> String? {
        usersByID[userID]?.fields.profile_image
    }

    /// Percent-encodes a string for use in URL query parameters.
    private func enc(_ raw: String) -> String {
        raw.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? raw
    }
}
