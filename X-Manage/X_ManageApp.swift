//
//  X_ManageApp.swift
//  X-Manage
//
//  Created by xiaoxin on 12/6/25.
//

import SwiftUI

@main
struct X_ManageApp: App {
    @StateObject private var authManager = AuthManager.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authManager)
        }
        .windowStyle(.automatic)
        .windowResizability(.contentSize)
        .defaultSize(width: 1200, height: 800)
    }
}

// MARK: - 根视图
struct RootView: View {
    @EnvironmentObject private var authManager: AuthManager

    var body: some View {
        Group {
            if authManager.isAuthenticated {
                MainView()
            } else {
                LoginView()
            }
        }
        .frame(minWidth: 1000, minHeight: 600)
    }
}
