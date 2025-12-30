//
//  SaleSpotApp.swift
//  SaleSpot
//
//  Created by Aastha Patel on 8/16/25.
//

import SwiftUI

@main
struct SaleSpotApp: App {
    @StateObject private var dataManager = DataManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager)
        }
    }
}
