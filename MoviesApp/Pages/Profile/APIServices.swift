//
//  APIService.swift
//  MoviesApp
//
//  Created by Reema Alsaleh  on 15/07/1447 AH.
//
import Foundation
import SwiftUI
import Combine

@MainActor
final class APIServices: ObservableObject {
    
    @Published var profiles: [profilerecord] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let baseURL = "https://api.airtable.com/v0/appsfcB6YESLj4NCN/users"
    private let token = "Bearer patHXtgI1qrXTZwz3.a455bfcc1a171662a512c7890954a8f4335f00601ea5d14d425baa3baa2d53c0"
    
    
    func updateProfile(_ updatedProfile: profilerecord) {
        if let index = profiles.firstIndex(where: { $0.id == updatedProfile.id }) {
            profiles[index] = updatedProfile
        }
    }
    func fetchProfiles() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            guard let url = URL(string: baseURL) else {
                throw URLError(.badURL)
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue(token, forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw URLError(.badServerResponse)
            }
            
            let decoder = JSONDecoder()
            let result = try decoder.decode(AirtableListResponseR<Profile>.self, from: data)
            
            profiles = result.records.map {
                profilerecord(id: $0.id, createdTime: $0.createdTime, fields: $0.fields)
            }
            
        } catch {
            errorMessage = error.localizedDescription
            print("Error fetching profiles: \(error)")
        }
    }
    
    func getProfile(by id: String) -> profilerecord? {
        return profiles.first { $0.id == id }
    }
    
    func getProfileByEmail(_ email: String) -> profilerecord? {
        return profiles.first { $0.fields.email == email }
    }
}
