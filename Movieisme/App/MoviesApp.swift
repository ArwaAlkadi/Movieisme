//
//  MoviesApp.swift
//  MoviesApp
//
//

import SwiftUI

@main
struct MoviesApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                SignInView()
            }
        }
    }
}
