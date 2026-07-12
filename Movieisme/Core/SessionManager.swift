//
//  SessionManager.swift
//  MoviesApp
//

import Foundation
import SwiftUI
import Combine

/// Manages the auth session (signed-in user or guest)
/// and persists it in UserDefaults across app launches.
@MainActor
final class SessionManager: ObservableObject {

    @Published var currentUserID: String?
    @Published var isGuest: Bool = false

    private let userIDKey = "currentUserID"
    private let guestKey  = "isGuest"

    init() {
        let saved = UserDefaults.standard.string(forKey: userIDKey)
        currentUserID = (saved?.isEmpty == false) ? saved : nil
        isGuest = UserDefaults.standard.bool(forKey: guestKey)
    }

    var isSignedIn: Bool { currentUserID != nil }

    /// True when the user should see the main app (signed in or guest).
    var isInsideApp: Bool { isSignedIn || isGuest }

    func signIn(userID: String) {
        currentUserID = userID
        isGuest = false
        persist()
    }

    func continueAsGuest() {
        currentUserID = nil
        isGuest = true
        persist()
    }

    func signOut() {
        currentUserID = nil
        isGuest = false
        persist()
    }

    private func persist() {
        UserDefaults.standard.set(currentUserID ?? "", forKey: userIDKey)
        UserDefaults.standard.set(isGuest, forKey: guestKey)
    }
}
