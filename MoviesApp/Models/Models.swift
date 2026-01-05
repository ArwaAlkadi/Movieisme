//
//  Models.swift
//  MoviesApp
//
//  Created by Arwa Alkadi on 24/12/2025.
//

import Foundation


// MARK: - Airtable Generic Response
struct AirtableListResponse<T: Codable>: Codable {
    let records: [AirtableRecord<T>]
}

struct AirtableRecord<T: Codable>: Codable, Identifiable {
    let id: String
    let createdTime: String
    let fields: T
}



// MARK: - Movies
struct MovieFields: Codable {
    let name: String
    let poster: String
    let story: String
    let runtime: String
    let genre: [String]
    let rating: String
    let IMDb_rating: Double
    let language: [String]
}

struct MovieDTO: Identifiable {
    let id: String
    let createdTime: String
    let fields: MovieFields
}



// MARK: - Reviews
struct ReviewFields: Codable {
    let rate: Int
    let review_text: String
    let movie_id: String
    let user_id: String
}

struct ReviewDTO: Identifiable {
    let id: String
    let createdTime: String
    let fields: ReviewFields
}

struct ReviewCreateDTO: Codable {
    struct Fields: Codable {
        let review_text: String
        let rate: Int
        let movie_id: String
        let user_id: String
    }
    let fields: Fields
}



// MARK: - Actors
struct ActorsFields: Codable {
    let name: String
    let image: String?
}

struct ActorsDTO: Identifiable {
    let id: String
    let createdTime: String
    let fields: ActorsFields
}



// MARK: - Directors
struct DirectorsFields: Codable {
    let name: String
    let image: String?
}

struct DirectorsDTO: Identifiable {
    let id: String
    let createdTime: String
    let fields: DirectorsFields
}



// MARK: - Users
struct UserFields: Codable {
    let name: String
    let profile_image: String?
}

struct UserDTO: Identifiable {
    let id: String
    let createdTime: String
    let fields: UserFields
}



// MARK: - Favorites
struct FavoriteCreateDTO: Codable {
    struct Fields: Codable {
        let user_id: String
        let movie_id: [String]
    }
    let fields: Fields
}



// MARK: - Movie Actors (Link Table)
struct MovieActorFields: Codable {
    let movie_id: String
    let actor_id: String
}

struct MovieActorDTO: Identifiable {
    let id: String
    let createdTime: String
    let fields: MovieActorFields
}



// MARK: - Movie Directors (Link Table)
struct MovieDirectorFields: Codable {
    let movie_id: String
    let director_id: String
}

struct MovieDirectorDTO: Identifiable {
    let id: String
    let createdTime: String
    let fields: MovieDirectorFields
}

