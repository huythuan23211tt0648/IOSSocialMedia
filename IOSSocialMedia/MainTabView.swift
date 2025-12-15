//
//  MainTabView.swift
//  IOSSocialMedia
//
//  Created by cao_dong on 10/12/25.
//
import SwiftUI

struct MainTabView: View {
    @StateObject var auth = AuthViewModel()
    
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
                ProfileLoggedInView()
                    .environmentObject(auth)
                    .navigationTitle("Profile")
                    .navigationBarHidden(true)
            }
            .tabItem {
                Image(systemName: "person.crop.circle")
                Text("Profile")
            }
           
        }
    }
}

