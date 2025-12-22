//
//  MainTabView.swift
//  IOSSocialMedia
//
//  Created by cao_dong on 10/12/25.
//
import SwiftUI

struct MainTabView: View {
    @StateObject var auth = AuthViewModel()
    @State private var selectedTab: MainTab = .home   // 👈 thêm dòng này

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
        TabView(selection: $selectedTab) {   // 👈 bind selection

            NavigationView {
                HomeView()
                    .navigationTitle("Home")
            }
            .tabItem {
                Image(systemName: "house.fill")
                Text("Home")
            }
            .tag(MainTab.home)   // 👈 tag

            NavigationView {
                CreatePostView(selectedTab: $selectedTab) // 👈 truyền binding
                    .navigationTitle("Create")
                    .navigationBarHidden(true)
            }
            .tabItem {
                Image(systemName: "plus.square")
                Text("Create")
            }
            .tag(MainTab.create)

            NavigationView {
                MessagesListView()
                    .navigationTitle("Messages")
            }
            .tabItem {
                Image(systemName: "paperplane")
                Text("Messages")
            }
            .tag(MainTab.messages)

            NavigationView {
                ProfileView()
                    .environmentObject(auth)
                    .navigationTitle("Profile")
                    .navigationBarHidden(true)
            }
            .tabItem {
                Image(systemName: "person.crop.circle")
                Text("Profile")
            }
            .tag(MainTab.profile)
        }
    }
}

