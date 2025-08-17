//
//  ContentView.swift
//  SaleSpot
//
//  Created by Aastha Patel on 8/16/25.
//

import SwiftUI

// Content View (Main Container with Tab Navigation)
struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            MapView()
                .tabItem {
                    Image(systemName: "map")
                    Text("Map")
                }
                .tag(0)
            
            ExploreView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Explore")
                }
                .tag(1)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person")
                    Text("Profile")
                }
                .tag(2)
        }
        .accentColor(.black)
    }
}

// Placeholder Views

struct MapView: View {
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                
                VStack(spacing: 16) {
                    Image(systemName: "map")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("Map View")
                        .font(.title2)
                        .fontWeight(.medium)
                    
                    Text("This is where we will show sales!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationTitle("Sales Near You")
        }
    }
}

struct ExploreView: View {
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                
                VStack(spacing: 16) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("Explore View")
                        .font(.title2)
                        .fontWeight(.medium)
                    
                    Text("This is where we will show a scrollable list of sales!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationTitle("Explore Sales")
        }
    }
}

struct ProfileView: View {
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                
                VStack(spacing: 16) {
                    Image(systemName: "person.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("Profile View")
                        .font(.title2)
                        .fontWeight(.medium)
                    
                    Text("This is where you'll manage your profile and create sales!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationTitle("Profile")
        }
    }
}

#Preview {
    ContentView()
}
