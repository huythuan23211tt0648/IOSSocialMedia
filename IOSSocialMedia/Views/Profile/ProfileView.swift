import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var auth: AuthViewModel
    
    var body: some View {
        NavigationView {
//            if auth.isLoggedIn {
//                ProfileLoggedInView()
//            } else {
//                LoginView()
//            }
            ProfileLoggedInView()
        }

        
    }
}
