//
//  MainTabView.swift
//  IOSSocialMedia
//
//  Created by cao_dong on 10/12/25.
//
import SwiftUI

struct MainTabView: View {

    
    // 1. Tạo biến quản lý Tab hiện tại (Mặc định là 0 - Home)
    @State private var selectedTab = 0
    
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
        // 2. Binding biến selectedTab vào TabView
        TabView(selection: $selectedTab) {

            NavigationView {
                // 3. Truyền binding này vào HomeView để HomeView có thể điều khiển
                HomeView(selectedTab: $selectedTab)
                    .navigationTitle("Home")
            }
            .tabItem {
                Image(systemName: "house.fill")
                Text("Home")
            }
            .tag(0) // 4. Đánh dấu thẻ này là số 0

            
            NavigationView {
                MessagesListView()
                    .navigationTitle("Messages")
            }
            .tabItem {
                Image(systemName: "paperplane")
                Text("Messages")
            }
            .tag(1) // Đánh dấu thẻ này là số 2

            NavigationView {
                ProfileView()
                    .navigationTitle("Profile")
                    .navigationBarHidden(true)
            }
            .tabItem {
                Image(systemName: "person.crop.circle")
                Text("Profile")
            }
            .tag(2) // 5. QUAN TRỌNG: Đánh dấu Tab Profile là số 3
            
        }
    }
}
