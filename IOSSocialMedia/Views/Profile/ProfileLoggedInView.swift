import SwiftUI

struct ProfileLoggedInView: View {
    @EnvironmentObject var auth: AuthViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Avatar + Username
                VStack {
                    Circle()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.gray.opacity(0.3))
                    
                    Text("Thuan Nguyen")
                        .font(.title2)
                        .bold()
                }
                .padding(.top, 20)
                
                Divider()
                
                // Posts grid placeholder
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 3), spacing: 2) {
                    ForEach(0..<12) { _ in
                        Rectangle()
                            .frame(height: 120)
                            .foregroundColor(.gray.opacity(0.4))
                    }
                }
                
                Divider()
                
                // Logout button
                Button(action: {
                    auth.isLoggedIn = false
                }) {
                    Text("Đăng xuất")
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(10)
                }
                .padding()
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
}
