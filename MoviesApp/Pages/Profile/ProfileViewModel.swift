//
//  ProfileViewModel.swift
//  MoviesApp
//
//  Created by Arwa Alkadi on 24/12/2025.
//
import Foundation

struct AirtableListResponseR<T: Codable>: Codable {
    let records: [AirtableRecordR<T>]
}

struct AirtableRecordR<T: Codable>: Codable, Identifiable {
    let id: String
    let createdTime: String
    var fields: T
}
struct profilerecord: Identifiable {
    let id: String
    let createdTime: String
    let fields : Profile
    
}

struct Profile:  Codable {
    var name: String
    let password : String
    let email: String
    let profile_image: String?

    
}
extension Profile {
    var firstName: String {
        name.components(separatedBy: " ").first ?? name
    }
    var lastName: String {
        let parts = name.components(separatedBy: " ")
        if parts.count > 1 {
            return parts.dropFirst().joined(separator: " ")
        } else {
            return ""
        }
    }
}


