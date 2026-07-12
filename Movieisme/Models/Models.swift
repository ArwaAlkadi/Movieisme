//
//  Models.swift
//  MoviesApp
//
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



// MARK: - اروى

/// Movies
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



/// Reviews
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

struct ReviewCreateDTO: Encodable {
    let fields: Fields

    struct Fields: Encodable {
        let review_text: String
        let rate: Int
        let movie_id: String
        let user_id: String
    }
}


///  Actors
struct ActorsFields: Codable {
    let name: String
    let image: String?
}

struct ActorsDTO: Identifiable {
    let id: String
    let createdTime: String
    let fields: ActorsFields
}



///  Directors
struct DirectorsFields: Codable {
    let name: String
    let image: String?
}

struct DirectorsDTO: Identifiable {
    let id: String
    let createdTime: String
    let fields: DirectorsFields
}



/// Users
struct UserFields: Codable {
    let name: String
    let profile_image: String?
}

struct UserDTO: Identifiable {
    let id: String
    let createdTime: String
    let fields: UserFields
}



/// Movie Actors (Link Table)
struct MovieActorFields: Codable {
    let movie_id: String
    let actor_id: String
}

struct MovieActorDTO: Identifiable {
    let id: String
    let createdTime: String
    let fields: MovieActorFields
}



/// Movie Directors (Link Table)
struct MovieDirectorFields: Codable {
    let movie_id: String
    let director_id: String
}

struct MovieDirectorDTO: Identifiable {
    let id: String
    let createdTime: String
    let fields: MovieDirectorFields
}



/// Profile (Users Table)
struct ProfileFields: Codable {
    var name: String
    let password: String
    let email: String
    var profile_image: String?
}

struct ProfileDTO: Identifiable {
    let id: String
    let createdTime: String
    var fields: ProfileFields
}

/// Favorites Read
struct FavoriteFields: Codable {
    let user_id: String
    let movie_id: [String]
}

struct FavoriteDTO: Identifiable {
    let id: String
    let createdTime: String
    let fields: FavoriteFields
}

/// Helpers
extension ProfileFields {
    var firstName: String {
        name.split(separator: " ").first.map(String.init) ?? name
    }
    var lastName: String {
        let parts = name.split(separator: " ")
        guard parts.count > 1 else { return "" }
        return parts.dropFirst().joined(separator: " ")
    }
}


// MARK: - Profile Update DTO (PATCH)
struct ProfileUpdateDTO: Codable {
    struct Fields: Codable {
        var name: String?
        var profile_image: String?
    }
    let fields: Fields
}
