//
//  MoviesCenterViewModel.swift
//  MoviesApp
//
//  Created by Arwa Alkadi on 24/12/2025.
//

/*
 
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
 
 */

import Foundation
import SwiftUI
import Combine

@MainActor
final class MoviesCenterViewModel: ObservableObject {

    // MARK: - UI State
    @Published var movies: [MovieDTO] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - API Config
    private let baseURL = "https://api.airtable.com/v0/appsfcB6YESLj4NCN"
    private let token  = "Bearer patHXtgI1qrXTZwz3.a455bfcc1a171662a512c7890954a8f4335f00601ea5d14d425baa3baa2d53c0"

    
    // MARK: - Fetch Movies (Main Function) اهم دالة
    func fetchMovies() async {

        isLoading = true            // 1) Start loading
        errorMessage = nil
        defer { isLoading = false } // 2) Stop loading

        do {
            
            // URL → Request → Send → Check status → Decode → Save
            
            // 3) Build URL
            guard let url = URL(string: "\(baseURL)/movies") else {
                throw URLError(.badURL)
            }

            // 4) Build Request
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue(token, forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Accept")

            // 5) Send request -> get (Data + Response)
            let (data, response) = try await URLSession.shared.data(for: request)

            // 6) Check status code (200...299 = success)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw URLError(.badServerResponse)
            }

            // 7) Decode JSON -> Swift Models
            let decoded = try JSONDecoder().decode(
                AirtableListResponse<MovieFields>.self,
                from: data
            )

            // 8) Convert AirtableRecord -> MovieDTO
            movies = decoded.records.map { record in
                MovieDTO(
                    id: record.id,
                    createdTime: record.createdTime,
                    fields: record.fields
                )
            }
            
        } catch {
            // 9) Save error for alert
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

    var highRated: [MovieDTO] {
        movies.sorted { $0.fields.IMDb_rating > $1.fields.IMDb_rating }
    }
}
