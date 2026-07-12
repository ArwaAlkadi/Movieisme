//
//  RootView.swift
//  MoviesApp
//

import SwiftUI

/// Decides which screen to show based on the session state:
/// signed-in or guest users go to the main app, otherwise Sign In.
struct RootView: View {

    @EnvironmentObject private var api: APIServices
    @EnvironmentObject private var session: SessionManager

    var body: some View {
        Group {
            if session.isInsideApp {
                NavigationStack {
                    MoviesCenterView(api: api)
                }
            } else {
                SignInView(api: api)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: session.isInsideApp)
    }
}

#Preview {
    RootView()
        .environmentObject(APIServices())
        .environmentObject(SessionManager())
}
