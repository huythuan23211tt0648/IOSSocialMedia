import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var auth: AuthViewModel
    
    var body: some View {
        Group {
            if auth.isLoggedIn {
                ProfileLoggedInView()
            } else {
                ProfileLoggedOutView()
            }
//            ProfileLoggedInView()
        }

        
    }
}
