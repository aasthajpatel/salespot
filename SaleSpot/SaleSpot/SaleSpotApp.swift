//
//  SaleSpotApp.swift
//  SaleSpot
//
//  Created by Aastha Patel on 8/16/25.
//

import SwiftUI
import FirebaseCore

@main
struct SaleSpotApp: App {
    @StateObject private var dataManager = DataManager()
    @StateObject private var authManager = AuthManager()
    @StateObject private var locationManager = LocationManager()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                ContentView()
                    .environmentObject(dataManager)
                    .environmentObject(authManager)
                    .environmentObject(locationManager)
            } else {
                AuthenticationView()
                    .environmentObject(authManager)
                    .environmentObject(dataManager)
                    .environmentObject(locationManager)
            }
        }
    }
}
