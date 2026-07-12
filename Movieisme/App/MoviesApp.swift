//
//  MoviesApp.swift
//  MoviesApp
//

import SwiftUI
import Combine

@main
struct MoviesApp: App {

    // Single shared instances for the whole app.
    @StateObject private var api = APIServices()
    @StateObject private var session = SessionManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(api)
                .environmentObject(session)
                .preferredColorScheme(.dark)
        }
    }
}
