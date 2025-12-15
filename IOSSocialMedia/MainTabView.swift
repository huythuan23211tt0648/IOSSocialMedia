//
//  MainTabView.swift
//  IOSSocialMedia
//
//  Created by cao_dong on 10/12/25.
//
import SwiftUI

struct MainTabView: View {
    @StateObject var auth = AuthViewModel()
    
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
    
    var body: some View {
        TabView {

            NavigationView {
                HomeView()
                    .navigationTitle("Home")
            }
            .tabItem {
                Image(systemName: "house.fill")
                Text("Home")
            }

            NavigationView {
                CreateView()
                    .navigationTitle("Create")
            }
            .tabItem {
                Image(systemName: "plus.square")
                Text("Create")
            }

            NavigationView {
                MessagesListView()
                    .navigationTitle("Messages")
            }
            .tabItem {
                Image(systemName: "paperplane")
                Text("Messages")
            }

            NavigationView {
                ProfileView()
                    .environmentObject(auth)
            }
            .tabItem {
                Image(systemName: "person.crop.circle")
                Text("Profile")
            }
        }
    }
}

