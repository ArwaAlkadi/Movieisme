//
//  MovieDetailsViewModel.swift
//  MoviesApp
//
//  Created by Arwa Alkadi on 24/12/2025.
//

/*
 
// شرح كل دالة ووظيفتها
 
===============================
fetchMovies
GET → movies
===============================
Tables:
- movies

URL
→ Request
→ Send
→ Check Status
→ Decode
→ Save movies


===============================
fetchReviews(movieID)
GET → reviews
===============================
Tables:
- reviews
- users (via fetchUsers)

URL (reviews + movie_id)
→ Request
→ Send
→ Check Status
→ Decode reviews
→ Save reviews
→ Get user_id list
→ Call fetchUsers


===============================
fetchUsers(userIDs)
GET → users
===============================
Tables:
- users

URL (users + RECORD_ID OR)
→ Request
→ Send
→ Check Status
→ Decode
→ Save users (Dictionary)


==============================================================
fetchActors(movieID)
GET → movie_actors                               🔴🔴🔴 
GET → actors

 الدالة تاخذ معرّف الفيلم، وتروح تبحث في جدول الروابط عشان تطلع معرّفات المخرجين اللي أخرجوا هذا الفيلم.
 بعدين تاخذ هالمعرّفات وتروح تجلب التفاصيل الكاملة (الاسم، الصورة، إلخ) من جدول المخرجين.

==============================================================
Tables:
- movie_actors (link table)
- actors

URL (movie_actors + movie_id)
→ Get actor_id
→ Build OR formula
→ URL (actors)
→ Decode
→ Save actors


==============================================================
fetchDirectors(movieID)
GET → movie_directors                             🔴🔴🔴
GET → directors
==============================================================
Tables:
- movie_directors (link table)
- directors

URL (movie_directors + movie_id)
→ Get director_id
→ Build OR formula
→ URL (directors)
→ Decode
→ Save directors


===============================
createReview
POST → reviews
===============================
Tables:
- reviews

Create Body
→ Encode JSON
→ URL
→ Request
→ Send
→ Check Status
→ Success / Fail


===============================
addToFavorites
POST → favorites
===============================
Tables:
- favorites

Create Body
→ Encode JSON
→ URL
→ Request
→ Send
→ Check Status
→ Success / Fail


===============================
deleteReview(reviewID)
DELETE → reviews
===============================
Tables:
- reviews

URL (reviewID)
→ Request
→ Send
→ Check Status
→ Delete locally from array


===============================
Helpers (No Network)
===============================
Tables:
- users (local cache only)

userName(for:)
userImage(for:)

Read from local dictionary only
 
 
*/







import Foundation
import Combine

@MainActor
final class MovieDetailsViewModel: ObservableObject {

    // MARK: - Published Data
    @Published var reviews: [ReviewDTO] = []
    @Published var actors: [ActorsDTO] = []
    @Published var directors: [DirectorsDTO] = []
    @Published var usersByID: [String: UserDTO] = [:]

    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - API Config
    let baseURL = "https://api.airtable.com/v0/appsfcB6YESLj4NCN"
    let token = "Bearer patHXtgI1qrXTZwz3.a455bfcc1a171662a512c7890954a8f4335f00601ea5d14d425baa3baa2d53c0"

    // Temporary user until login
    let defaultUserID = "recaLvl1OOPjSagCx"


    // ===============================
    // fetchReviews(movieID)
    // GET → reviews
    // ===============================
    func fetchReviews(movieID: String) async {

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            var comps = URLComponents(string: "\(baseURL)/reviews")
            comps?.queryItems = [
                URLQueryItem(
                    name: "filterByFormula",
                    value: #"movie_id="\#(movieID)""#
                )
            ]

            guard let url = comps?.url else { return }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue(token, forHTTPHeaderField: "Authorization")

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode) else { return }

            let decoded = try JSONDecoder().decode(
                AirtableListResponse<ReviewFields>.self,
                from: data
            )

            reviews = decoded.records
                .sorted { $0.createdTime > $1.createdTime }
                .map {
                    ReviewDTO(
                        id: $0.id,
                        createdTime: $0.createdTime,
                        fields: $0.fields
                    )
                }

            let userIDs = Array(Set(reviews.map { $0.fields.user_id }))
            await fetchUsers(userIDs: userIDs)

        } catch {
            errorMessage = error.localizedDescription
        }
    }


    // ===============================
    // fetchUsers(userIDs)
    // GET → users
    // ===============================
    func fetchUsers(userIDs: [String]) async {

        let ids = Array(Set(userIDs))
        guard !ids.isEmpty else { return }

        do {
            let formula = "OR(" +
                ids.map { #"RECORD_ID()="\#($0)""# }.joined(separator: ",")
                + ")"

            var comps = URLComponents(string: "\(baseURL)/users")
            comps?.queryItems = [
                URLQueryItem(name: "filterByFormula", value: formula)
            ]

            guard let url = comps?.url else { return }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue(token, forHTTPHeaderField: "Authorization")

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode) else { return }

            let decoded = try JSONDecoder().decode(
                AirtableListResponse<UserFields>.self,
                from: data
            )

            let users = decoded.records.map {
                UserDTO(id: $0.id, createdTime: $0.createdTime, fields: $0.fields)
            }

            usersByID = Dictionary(uniqueKeysWithValues: users.map { ($0.id, $0) })

        } catch {
            errorMessage = error.localizedDescription
        }
    }


    // ===============================
    // createReview
    // POST → reviews
    // ===============================
    func createReview(movieID: String, text: String, rate: Int) async -> Bool {

        do {
            guard let url = URL(string: "\(baseURL)/reviews") else { return false }

            let body = ReviewCreateDTO(
                fields: .init(
                    review_text: text,
                    rate: rate,
                    movie_id: movieID,
                    user_id: defaultUserID
                )
            )

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue(token, forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(body)

            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode) else { return false }

            return true

        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }


    // ===============================
    // deleteReview(reviewID)
    // DELETE → reviews
    // ===============================
    func deleteReview(reviewID: String) async -> Bool {

        do {
            guard let url = URL(string: "\(baseURL)/reviews/\(reviewID)") else { return false }

            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            request.setValue(token, forHTTPHeaderField: "Authorization")

            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode) else { return false }

            reviews.removeAll { $0.id == reviewID }
            return true

        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }



    // ===============================
    // fetchActors(movieID)
    // GET → movie_actors → actors
    // ===============================
    func fetchActors(movieID: String) async {

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // 1) GET movie_actors (links)
            var comps = URLComponents(string: "\(baseURL)/movie_actors")
            comps?.queryItems = [
                URLQueryItem(name: "filterByFormula", value: #"movie_id="\#(movieID)""#)
            ]
            guard let url = comps?.url else { return }

            var req = URLRequest(url: url)
            req.httpMethod = "GET"
            req.setValue(token, forHTTPHeaderField: "Authorization")
            req.setValue("application/json", forHTTPHeaderField: "Accept")

            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                throw URLError(.badServerResponse)
            }

            let links = try JSONDecoder().decode(AirtableListResponse<MovieActorFields>.self, from: data)
            let actorIDs = links.records.map { $0.fields.actor_id }
            guard !actorIDs.isEmpty else { actors = []; return }

            // 2) GET actors by RECORD_ID()
            let formula = "OR(" + actorIDs.map { #"RECORD_ID()="\#($0)""# }.joined(separator: ",") + ")"

            var comps2 = URLComponents(string: "\(baseURL)/actors")
            comps2?.queryItems = [URLQueryItem(name: "filterByFormula", value: formula)]
            guard let url2 = comps2?.url else { return }

            var req2 = URLRequest(url: url2)
            req2.httpMethod = "GET"
            req2.setValue(token, forHTTPHeaderField: "Authorization")
            req2.setValue("application/json", forHTTPHeaderField: "Accept")

            let (data2, resp2) = try await URLSession.shared.data(for: req2)
            guard let http2 = resp2 as? HTTPURLResponse, (200...299).contains(http2.statusCode) else {
                throw URLError(.badServerResponse)
            }

            let decoded = try JSONDecoder().decode(AirtableListResponse<ActorsFields>.self, from: data2)
            actors = decoded.records.map { ActorsDTO(id: $0.id, createdTime: $0.createdTime, fields: $0.fields) }

        } catch {
            errorMessage = error.localizedDescription
        }
    }


    // ===============================
    // fetchDirectors(movieID)
    // GET → movie_directors → directors
    // ===============================
    func fetchDirectors(movieID: String) async {

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // 1) GET movie_directors (links)
            var comps = URLComponents(string: "\(baseURL)/movie_directors")
            comps?.queryItems = [
                URLQueryItem(name: "filterByFormula", value: #"movie_id="\#(movieID)""#)
            ]
            guard let url = comps?.url else { return }

            var req = URLRequest(url: url)
            req.httpMethod = "GET"
            req.setValue(token, forHTTPHeaderField: "Authorization")
            req.setValue("application/json", forHTTPHeaderField: "Accept")

            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                throw URLError(.badServerResponse)
            }

            let links = try JSONDecoder().decode(AirtableListResponse<MovieDirectorFields>.self, from: data)
            let directorIDs = Array(Set(links.records.map { $0.fields.director_id }))
            guard !directorIDs.isEmpty else { directors = []; return }

            // 2) GET directors by RECORD_ID()
            let formula = "OR(" + directorIDs.map { #"RECORD_ID()="\#($0)""# }.joined(separator: ",") + ")"

            var comps2 = URLComponents(string: "\(baseURL)/directors")
            comps2?.queryItems = [URLQueryItem(name: "filterByFormula", value: formula)]
            guard let url2 = comps2?.url else { return }

            var req2 = URLRequest(url: url2)
            req2.httpMethod = "GET"
            req2.setValue(token, forHTTPHeaderField: "Authorization")
            req2.setValue("application/json", forHTTPHeaderField: "Accept")

            let (data2, resp2) = try await URLSession.shared.data(for: req2)
            guard let http2 = resp2 as? HTTPURLResponse, (200...299).contains(http2.statusCode) else {
                throw URLError(.badServerResponse)
            }

            let decoded = try JSONDecoder().decode(AirtableListResponse<DirectorsFields>.self, from: data2)
            directors = decoded.records.map { DirectorsDTO(id: $0.id, createdTime: $0.createdTime, fields: $0.fields) }

        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // ===============================
    // Helpers (No Network)
    // ===============================
    func userName(for userID: String) -> String {
        usersByID[userID]?.fields.name ?? "User"
    }

    func userImage(for userID: String) -> String? {
        usersByID[userID]?.fields.profile_image
    }
}
