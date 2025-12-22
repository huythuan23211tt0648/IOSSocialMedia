import SwiftUI
import Firebase
import FirebaseAuth

struct ProfileLoggedInView: View {
    @State private var isDarkMode = false
    
    // 1. Khởi tạo Service
    @StateObject var userService = UserService()

    // 2. Giả sử PostService đã có sẵn (bạn inject vào hoặc khởi tạo mới)
    @ObservedObject var postService = PostService.shared
    
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            
            if userService.isLoading {
                ProgressView()
            } else if let user = userService.currentUser {
                // Đã có dữ liệu User -> Hiển thị giao diện
                VStack(spacing: 0) {
                    // Truyền username vào Header để hiển thị
                    HeaderView(isDarkMode: $isDarkMode, username: user.username)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 10) {
                            
                            // Truyền User object xuống các View con
                            ProfileHeaderView(user: user)
                            BioView(user: user)
                            FollowedByView()
                            
                            // Logic nút bấm dựa trên ID
                            if user.id == Auth.auth().currentUser?.uid {
                                ActionButtonsForMySelfView()
                            } else {
                                ActionButtonsView()
                            }
                            
                            HighlightView()
                            TabsView()
                            
                            // Truyền danh sách bài viết từ PostService vào Grid
                            PhotoGridsView(posts: postService.posts)
                            
                        }.padding(20)
                    }
                    .refreshable {
                        // Kéo để reload cả 2
                        await userService.fetchCurrentUser()
                        // Gọi hàm load post của service có sẵn (ví dụ: fetchPosts)
                        if let uid = user.id {
                                                    await PostService.shared.fetchUserPosts(uid: uid)
                                                }
                    }
                }
            } else {
                // Trường hợp chưa load được hoặc lỗi
                Text("Không thể tải thông tin cá nhân")
                    .onAppear {
                        Task { await userService.fetchCurrentUser() }
                    }
            }
        }
        .navigationTitle("")
        .navigationBarHidden(true)
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .task {
            // Tự động load dữ liệu khi vào màn hình
            await userService.fetchCurrentUser()
            if let uid = userService.currentUser?.id {
                // Gọi service có sẵn của bạn
                await PostService.shared.fetchUserPosts(uid: uid)
            }
        }
    }
}
// MARK: - 1. HEADER
private struct HeaderView: View {
    @Binding var isDarkMode: Bool
    var username: String // Nhận tên user
    @EnvironmentObject var authViewModel: AuthViewModel
    var body: some View {
        HStack {
            Text(username) // Hiển thị tên user trên thanh header
                .font(.title2).fontWeight(.bold)
            Spacer()
            Button(action: { isDarkMode.toggle() }) {
                Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                    .font(.title2).foregroundColor(.primary)
            }
            Menu {
                // 👇 Các nút con bên trong Menu
                
                // Nút 1: Cài đặt (Ví dụ thêm vào cho đỡ trống)
                Button(action: {
                    print("Mở cài đặt")
                }) {
                    Label("Cài đặt", systemImage: "gear")
                }
                
                // Nút 2: Đăng xuất (Dùng role .destructive để chữ màu đỏ)
                Button(role: .destructive, action: {
                    authViewModel.signOut()
                }) {
                    Label("Đăng xuất", systemImage: "rectangle.portrait.and.arrow.right")
                }
                
            } label: {
                // 👇 Hình ảnh hiển thị bên ngoài (Hamburger icon)
                Image(systemName: "line.3.horizontal")
                    .font(.title2)
                    .padding(.leading, 15)
                    .foregroundColor(.primary) // Thêm màu để đảm bảo hiển thị tốt trên Dark Mode
            }
           
            
        }
        .padding()
        .background(Color(UIColor.systemBackground))
    }
}

// MARK: - 2. PROFILE INFO (Avatar + Số liệu)
private struct ProfileHeaderView: View {
    let user: User // Nhận model User
    
    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            // Avatar
            if let base64String = user.profileImageUrl, !base64String.isEmpty {
                Base64ImageView(base64String: base64String)
                    .frame(width: 90, height: 90)
                    .clipShape(Circle())
            
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 85, height: 85)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Stats (Dùng dữ liệu thật từ model)
            HStack(spacing: 20) {
                StatView(number: "\(user.postsCount)", label: "bài viết")
                StatView(number: "\(user.followersCount)", label: "người theo dõi")
                StatView(number: "\(user.followingCount)", label: "đang theo dõi")
            }
            Spacer()
        }.padding(.horizontal)
    }
}

// Component con hiển thị số (Reusable Component)
private struct StatView:View {
    let number : String
    let label : String
    var body: some View {
        VStack(spacing:2){
            Text(number)
                .font(.headline)
                .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                .foregroundColor(.primary)
            Text(label)
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(1)
        }
    }
}

// MARK: - 3. BIO (Tiểu sử)
private struct BioView: View {
    let user: User
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            // Tên hiển thị
            Text(user.username) // Hoặc tên thật nếu bạn có field fullName
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            // Danh xưng (Pronouns)
            if let pronouns = user.pronouns, !pronouns.isEmpty {
                Text(pronouns)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // Tiểu sử
            if let bio = user.bio, !bio.isEmpty {
                Text(bio)
                    .foregroundColor(.primary)
            }
            
            // Website Link
            if let website = user.socialLinks?.website, !website.isEmpty {
                HStack(spacing: 5) {
                    Image(systemName: "link").font(.caption)
                    Link(destination: URL(string: website) ?? URL(string: "https://google.com")!) {
                        Text(website)
                            .foregroundColor(Color(UIColor.systemBlue))
                            .lineLimit(1)
                    }
                }
            }
            
            // Threads Link (Badge)
            if let threads = user.socialLinks?.threads, !threads.isEmpty {
                HStack {
                    Image(systemName: "at").font(.caption)
                    Text(threads).font(.caption)
                }
                .padding(6)
                .background(Color(UIColor.secondarySystemBackground))
                .clipShape(Capsule())
                .padding(.top, 4)
            }
        }
        .padding(.horizontal)
        .font(.subheadline)
    }
}

// MARK: - 4. FOLLOWED BY
private struct FollowedByView:View {
    var body: some View {
        HStack{
            // avatar chong len nhau
            ZStack{
                Circle().fill(Color.gray).frame(width:20)
                Circle().fill(Color(UIColor.systemBackground)).frame(width:20).offset(x:14)
                Circle().fill(Color.blue).frame(width:20).offset(x:28)
            }
            .frame(width: 50,height: 20,alignment: .leading)
            Text("Có **wife_meoz**, **npdand** và **namcito** theo dõi")
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(1)
            
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// MARK: - 5. ACTION BUTTONS
private struct ActionButtonsView : View {
    @State private var isFollowing = false
    var body: some View {
        HStack(spacing : 8){
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)){
                    isFollowing.toggle()
                }
                
            }) {
                Text(isFollowing ? "Đang theo dõi":"Theo dõi" )
                    .font(.footnote)
                    .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical ,8)
                // Nếu đang theo dõi: Màu nền xám nhạt. Nếu chưa: Màu xanh
                    .background(isFollowing ? Color(UIColor.secondarySystemBackground) : Color.blue)
                // Nếu đang theo dõi: Chữ đen/trắng (theo theme). Nếu chưa: Chữ trắng
                    .foregroundColor(isFollowing ? .primary : .white)
                    .cornerRadius(8)
            }
            Button(action: {}) {
                Text("Nhắn tin")
                    .font(.footnote)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(Color(UIColor.secondarySystemBackground)) // Xám nhạt
                    .foregroundColor(.primary)
                    .cornerRadius(8)
            }
            
        }
    }
}

// MARK: button for my profile
private struct ActionButtonsForMySelfView:View {
    @State private var showEditProfile = false
    var body: some View {
        HStack(spacing :8){
            Button(action:{
                showEditProfile = true
            }){
                Text("Chỉnh sửa trang cá nhân")
                    .font(.footnote)
                    .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                    .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/)
                    .padding(.vertical,9)
                    .background(Color(UIColor.secondarySystemBackground))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
            }
        }
        // 3. Gắn sheet vào View cha
                    .sheet(isPresented: $showEditProfile) {
                        EditProfileView() // Gọi View chỉnh sửa tại đây
                    }
    }
}

// MARK: - 6. HIGHLIGHTS
private struct HighlightView:View {
    let items = ["Link Áo 🕺", "Feedback🎯", "📦", "Q&A"]
    var body: some View {
        ScrollView(.horizontal,showsIndicators: false){
            HStack(spacing: 15){
                ForEach(items,id: \.self) { item in
                    VStack{
                        Circle()
                            .fill(Color(UIColor.secondarySystemBackground))
                            .frame(width: 60,height: 60)
                            .overlay(
                                Circle().stroke(Color(uiColor: .separator),lineWidth: 1)
                            )
                            .overlay(Image(systemName: "photo")
                                .foregroundColor(.primary))
                        Text(item)
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 10)
    }
}

// MARK: - 7. TABS
private struct TabsView:View {
    var body: some View {
        HStack(spacing : 0){
            VStack{
                Image(systemName:"square.grid.3x3")
                    .font(.title3)
                Rectangle().frame(height: 1).foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
                
            }
            .foregroundColor(.blue)
            .frame(maxWidth: .infinity)
            //            VStack{
            //                Image(systemName: "play.rectangle")
            //                    .font(.title3)
            //                    .foregroundColor(.gray)
            //                Rectangle().frame(height: 1).foregroundColor(.clear)
            //            }
            //            .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/)
            //            VStack{
            //                Image(systemName: "person.crop.square")
            //                    .font(.title3)
            //                    .foregroundColor(.gray)
            //                Rectangle().frame(height: 1).foregroundColor(.clear)
            //            }
            //            .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/)
        }
    }
}


// MARK: - 8. PHOTO GRID (Updated for Base64)
private struct PhotoGridsView: View {
    let posts: [Post]
    
    // Cấu hình Grid 3 cột, khoảng cách 1px
    let columns = [
        GridItem(.flexible(), spacing: 1),
        GridItem(.flexible(), spacing: 1),
        GridItem(.flexible(), spacing: 1)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 1) {
            ForEach(posts) { post in
                // Logic: Lấy chuỗi ảnh đầu tiên trong mảng
                if let firstBase64String = post.imageUrls.first {
                    
                    // 👇 SỬA Ở ĐÂY: Bao bọc hình ảnh bên trong NavigationLink
                    // Lưu ý: Dùng `destination:` và mở ngoặc nhọn `{`
                    NavigationLink(destination: MyPostsView(
                        uid: Auth.auth().currentUser?.uid ?? "",
                        scrollToPostId: post.id // 👈 Truyền ID bài viết vào đây
                    )) {
                        
                        GeometryReader { geo in
                            // Gọi Component hiển thị Base64 đã tạo ở trên
                            Base64ImageView(base64String: firstBase64String)
                                .scaledToFill() // Fill đầy ô vuông
                                .frame(width: geo.size.width, height: geo.size.width) // Ép size vuông theo chiều rộng cột
                                .clipped() // Cắt phần thừa
                        }
                        .aspectRatio(1, contentMode: .fit) // Giữ khung hình vuông
                        .overlay(
                            // Logic: Nếu có nhiều hơn 1 ảnh thì hiện icon "Nhiều lớp"
                            Group {
                                if post.imageUrls.count > 1 {
                                    Image(systemName: "square.fill.on.square.fill")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .shadow(radius: 2)
                                }
                            },
                            alignment: .topTrailing
                        )
                        
                    } // 👆 Đóng ngoặc NavigationLink tại đây
                }
            }
        }
    }
}

//struct ProfileLoggedInView_Previews: PreviewProvider {
//    static var previews: some View {
//        ProfileLoggedInView()
//    }
//}
