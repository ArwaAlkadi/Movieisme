//
//  ProfileViewModel.swift
//  MoviesApp
//
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class ProfileViewModel: ObservableObject {

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var profiles: [ProfileDTO] = []

    private let api: APIServices

    init(api: APIServices) {
        self.api = api
    }

    func fetchProfiles() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await api.fetchProfiles()
            profiles = api.profiles
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func getProfile(by id: String) -> ProfileDTO? {
        api.getProfile(by: id)
    }

    func saveProfile(_ profile: ProfileDTO) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await api.saveProfileToAPI(profile)
            profiles = api.profiles
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func binding(for recordID: String) -> Binding<ProfileDTO> {
        Binding(
            get: {
                self.api.getProfile(by: recordID)
                ?? ProfileDTO(
                    id: recordID,
                    createdTime: "",
                    fields: .init(name: "", password: "", email: "", profile_image: nil)
                )
            },
            set: { updated in
                self.api.updateProfileLocal(updated)
                self.profiles = self.api.profiles
            }
        )
    }
}
