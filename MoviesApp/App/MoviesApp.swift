//
//  MoviesApp.swift
//  MoviesApp
//
//  Created by Arwa Alkadi on 24/12/2025.
//

import SwiftUI

@main
struct MoviesApp: App {
    var body: some Scene {
        WindowGroup {
            ProfileView()
            NavigationStack {
                MoviesCenterView()
            }
        }
    }
}
