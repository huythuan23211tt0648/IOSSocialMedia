//
//  IOSSocialMediaApp.swift
//  IOSSocialMedia
//
//  Created by thuan on 10/12/2025.
//

import SwiftUI
import Firebase

//
class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()

    return true
  }
}

@main
struct IOSSocialMediaApp: App {
    @StateObject var auth = AuthViewModel()

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    

    
    var body: some Scene {
        WindowGroup {
            Group {
                if (auth.isLoggedIn){
                    MainTabView()
                    
                }else{
                    NavigationView{
                        LoginView()
                    }
                }
            }.environmentObject(auth)
//            MyPostsView()
//            EditProfileView()
        }
    }
}
