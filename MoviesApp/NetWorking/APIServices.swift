//
//  APIService.swift
//  MoviesApp
//
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

    
    
    // ========================================
    // MARK: - API Configuration
    // ========================================
    
    private let baseURL = "https://api.airtable.com/v0/appsfcB6YESLj4NCN"
    private let token   = "Bearer patHXtgI1qrXTZwz3.a455bfcc1a171662a512c7890954a8f4335f00601ea5d14d425baa3baa2d53c0"

    
    
    // ========================================
    // MARK: - Network: Request Builder
    // ========================================
    
    /// Builds URLRequest with headers and optional body
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

    /// Validates HTTP response status and throws error if request failed
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
    
    /// Fetches all movies from Airtable
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
    
    /// Fetches all user profiles from Airtable
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

    /// Fetches users once for review cards (cached)
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

    /// Updates profile to Airtable (PATCH request)
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
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    
    
    // ========================================
    // MARK: - Network: Reviews
    // ========================================
    
    /// Fetches all reviews for a specific movie
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

            reviewsByMovieID[movieID] = decoded.records.map {
                ReviewDTO(
                    id: $0.id,
                    createdTime: $0.createdTime,
                    fields: $0.fields
                )
            }

            try await fetchUsersIfNeeded()
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    /// Creates a new review (POST request)
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

    /// Deletes a review (DELETE request)
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
    // MARK: - Network: Actors
    // ========================================
    
    /// Fetches all actors for a specific movie
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
    
    /// Fetches all directors for a specific movie
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
    
    /// Returns profile by ID from local cache
    func getProfile(by id: String) -> ProfileDTO? {
        profiles.first { $0.id == id }
    }

    /// Returns profile by email from local cache
    func getProfileByEmail(_ email: String) -> ProfileDTO? {
        profiles.first { $0.fields.email == email }
    }

    /// Updates profile in local cache only
    func updateProfileLocal(_ updated: ProfileDTO) {
        if let idx = profiles.firstIndex(where: { $0.id == updated.id }) {
            profiles[idx] = updated
        }
    }

    /// Returns user name from local cache or "User" if not found
    func userName(for userID: String) -> String {
        usersByID[userID]?.fields.name ?? "User"
    }

    /// Returns user image URL from local cache
    func userImageURL(for userID: String) -> String? {
        usersByID[userID]?.fields.profile_image
    }

    /// Encodes string for URL query parameters
    private func enc(_ raw: String) -> String {
        raw.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? raw
    }
}
