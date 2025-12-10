import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    
                    // MARK: Stories
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(0..<10) { i in
                                VStack {
                                    Circle()
                                        .strokeBorder(
                                            AngularGradient(
                                                gradient: Gradient(colors: [.red, .orange, .purple, .red]),
                                                center: .center
                                            ),
                                            lineWidth: 3
                                        )
                                        .frame(width: 70, height: 70)
                                        .overlay(
                                            Circle()
                                                .frame(width: 65, height: 65)
                                                .foregroundColor(.gray.opacity(0.3))
                                        )
                                    
                                    Text("User \(i)")
                                        .font(.caption)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                    }
                    
                    Divider()
                    
                    // MARK: Posts
                    VStack(spacing: 20) {
                        ForEach(0..<5) { i in
                            PostView(username: "User \(i)")
                        }
                    }
                }
            }
            .navigationTitle("") // 1. Sửa thành rỗng để xóa chữ Instagram bị thừa/lỗi
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarItems(
                        leading: HStack(spacing: 10) { // 2. Thêm spacing để các icon không dính nhau
                            Image(systemName: "camera")
                                .font(.title2)
                            
                            // 3. THÊM LOGO/CHỮ VÀO ĐÂY (Trong phần leading)
                            Text("Instagram")
                                .font(Font.custom("Billabong", size: 24)) // Hoặc dùng .system nếu không có font
                                .padding(.bottom, 2) // Căn chỉnh một chút cho thẳng hàng
                        },
                        trailing: HStack(spacing: 15) {
                            Image(systemName: "heart")
                                .font(.title2)
                            Image(systemName: "paperplane")
                                .font(.title2)
                        }
                    )
                }
            }
}

struct PostView: View {
    var username: String
    
    var body: some View {
        VStack(alignment: .leading) {
            
            // MARK: Header
            HStack {
                Circle()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.gray.opacity(0.3))
                
                Text(username)
                    .font(.headline)
                
                Spacer()
                
                Image(systemName: "ellipsis")
            }
            .padding(.horizontal)
            
            // MARK: Image
            Rectangle()
                .frame(height: 300)
                .foregroundColor(.gray.opacity(0.4))
            
            // MARK: Action buttons
            HStack(spacing: 20) {
                Image(systemName: "heart")
                    .font(.title2)
                Image(systemName: "bubble.right")
                    .font(.title2)
                Image(systemName: "paperplane")
                    .font(.title2)
                
                Spacer()
                
                Image(systemName: "bookmark")
                    .font(.title2)
            }
            .padding(.horizontal)
            .padding(.top, 5)
            
            // MARK: Caption
            VStack(alignment: .leading, spacing: 4) {
                Text("\(username) ")
                    .bold()
                + Text("This is a sample Instagram caption.")
            }
            .padding(.horizontal)
            .padding(.top, 5)
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
