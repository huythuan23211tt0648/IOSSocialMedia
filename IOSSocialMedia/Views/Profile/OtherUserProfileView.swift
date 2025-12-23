//
//  OtherUserProfileView.swift
//  IOSSocialMedia
//
//  Created by cao_dong on 23/12/25.
//

import SwiftUI
import Firebase
import FirebaseAuth

// MARK: - MAIN VIEW: Trang cá nhân người khác
struct OtherUserProfileView: View {
    let uid: String // ID của người dùng cần xem
    
    @State private var isDarkMode = false
    @StateObject var userService = UserService()
    @ObservedObject var postService = PostService.shared
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground).ignoresSafeArea()
            
            if userService.isLoading {
                ProgressView()
            } else if let user = userService.currentUser {
                
                VStack(spacing: 0) {
                    // Header: Chỉ hiển thị tên và nút back (mặc định của Navigation)
                    // Nếu muốn custom header thì thêm vào đây
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 10) {
                            
                            // 1. Info & Bio
                            ProfileHeaderView(user: user)
                            BioView(user: user)
                            
                            // 2. Nút hành động (Follow/Message)
                            ActionButtonsView(user: user)
                            
                            // 3. Highlights & Tabs
                            HighlightView()
                            TabsView()
                            
                            // 4. Grid ảnh (Bài viết của người đó)
                            // Truyền uid của người đó vào NavigationLink để mở đúng bài viết
                            PhotoGridsView(posts: postService.posts, userId: uid)
                            
                        }.padding(20)
                    }
                    .refreshable {
                        await loadData()
                    }
                }
                .navigationTitle(user.username) // Hiển thị tên trên thanh điều hướng chuẩn
                .navigationBarTitleDisplayMode(.inline)
                
            } else {
                Text("Không thể tải thông tin người dùng")
                    .foregroundColor(.gray)
            }
        }
        .onAppear {
            Task { await loadData() }
        }
    }
    
    // Hàm load dữ liệu riêng cho UID này
    func loadData() async {
        // 1. Load User Info theo UID
        await userService.fetchUserById(uid: uid)
        
        // 2. Load Posts theo UID
        await postService.fetchUserPosts(uid: uid)
    }
}

// MARK: - SERVICE MỞ RỘNG (Thêm hàm fetchUserById vào UserService nếu chưa có)
extension UserService {
    func fetchUserById(uid: String) async {
        await MainActor.run { self.isLoading = true }
        do {
            let snapshot = try await Firestore.firestore().collection("users").document(uid).getDocument()
            let user = try snapshot.data(as: User.self)
            await MainActor.run {
                self.currentUser = user
                self.isLoading = false
            }
        } catch {
            print("Lỗi fetch user by id: \(error)")
            await MainActor.run { self.isLoading = false }
        }
    }
}

// MARK: - SUB-VIEWS (Copy lại từ ProfileLoggedInView nhưng chỉnh sửa nhẹ)

// 1. ProfileHeaderView (Giữ nguyên, chỉ cần copy)
private struct ProfileHeaderView: View {
    let user: User
    
    var body: some View {
        HStack(alignment: .center, spacing: 10) {
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
            
            HStack(spacing: 20) {
                StatView(number: "\(user.postsCount)", label: "bài viết")
                StatView(number: "\(user.followersCount)", label: "người theo dõi")
                StatView(number: "\(user.followingCount)", label: "đang theo dõi")
            }
            Spacer()
        }
    }
}

// MARK: 2. StatView (Giữ nguyên)
private struct StatView: View {
    let number: String
    let label: String
    var body: some View {
        VStack(spacing: 2) {
            Text(number).font(.headline).fontWeight(.bold)
            Text(label).font(.caption).lineLimit(1)
        }
    }
}

// MARK: 3. BioView (Giữ nguyên)
private struct BioView: View {
    let user: User
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(user.username).fontWeight(.bold)
            if let pronouns = user.pronouns, !pronouns.isEmpty {
                Text(pronouns).font(.caption).foregroundColor(.gray)
            }
            if let bio = user.bio, !bio.isEmpty {
                Text(bio)
            }
            // Link website... (Copy logic cũ nếu cần)
        }
        .font(.subheadline)
    }
}

// MARK: 4. ActionButtonsView (Nút Follow/Message - Dành cho người lạ)
// 1. Sửa 'rivate' thành 'private'
private struct ActionButtonsView: View {
    // 👇 2. THÊM BIẾN NÀY ĐỂ NHẬN DỮ LIỆU NGƯỜI CẦN FOLLOW
    let user: User
    
    @State private var isFollowing = false
    @State private var isProcessing = false
    
    var body: some View {
        HStack(spacing: 8) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    // Không toggle ở đây, để hàm handle xử lý logic cho an toàn
                    handleFollowTapped()
                }
            }) {
                Text(isFollowing ? "Đang theo dõi" : "Theo dõi")
                    .font(.footnote).fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(isFollowing ? Color(UIColor.secondarySystemBackground) : Color.blue)
                    .foregroundColor(isFollowing ? .primary : .white)
                    .cornerRadius(8)
            }
            .disabled(isProcessing) // Khóa nút khi đang xử lý
            
            Button(action: {}) {
                Text("Nhắn tin")
                    .font(.footnote).fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color(UIColor.secondarySystemBackground))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
            }
        }
        .padding(.vertical, 10)
        .task {
            await checkFollowStatus()
        }
    }
    
    // --- LOGIC ---
    
    func checkFollowStatus() async {
        // 👇 3. SỬA: Lấy ID của người đang xem (Target User), KHÔNG LẤY current user
        guard let targetUid = user.id else { return }
        
        do {
            // Hàm này kiểm tra: "Tôi (Auth) có đang follow ông (targetUid) không?"
            let status = try await UserService().checkIfUserIsFollowed(uid: targetUid)
            await MainActor.run { isFollowing = status }
        } catch {
            print("Lỗi check follow: \(error)")
        }
    }
    
    func handleFollowTapped() {
        // 👇 4. SỬA: Lấy ID của người đang xem (Target User)
        guard let targetUid = user.id else { return }
        
        isProcessing = true
        
        // Optimistic Update
        let previousState = isFollowing
        isFollowing.toggle()
        
        Task {
            do {
                if previousState {
                    // Unfollow người có id là targetUid
                    try await UserService().unfollow(uid: targetUid)
                    print("Đã hủy theo dõi")
                } else {
                    // Follow người có id là targetUid
                    try await UserService().follow(uid: targetUid)
                    print("Đã theo dõi")
                }
                isProcessing = false
            } catch {
                print("Lỗi follow API: \(error)")
                await MainActor.run {
                    isFollowing = previousState // Hoàn tác nếu lỗi
                    isProcessing = false
                }
            }
        }
    }
}

// MARK: . Highlight & Tabs (Giữ nguyên - Chỉ là UI tĩnh)
private struct HighlightView: View {
    var body: some View {
        // ... (Copy code cũ)
        Text("Highlights").font(.caption).foregroundColor(.gray).padding(.vertical)
    }
}

private struct TabsView: View {
    var body: some View {
        VStack {
            Image(systemName: "square.grid.3x3").font(.title3).foregroundColor(.primary)
            Rectangle().frame(height: 1).foregroundColor(.primary)
        }
    }
}

// MARK: . PhotoGridsView (Đã sửa để nhận userId từ bên ngoài)
private struct PhotoGridsView: View {
    let posts: [Post]
    let userId: String // ID của chủ nhân trang cá nhân này
    
    let columns = [
        GridItem(.flexible(), spacing: 1),
        GridItem(.flexible(), spacing: 1),
        GridItem(.flexible(), spacing: 1)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 1) {
            ForEach(posts) { post in
                if let firstBase64String = post.imageUrls.first {
                    
                    // Điều hướng sang trang xem chi tiết bài viết
                    // Truyền đúng userId của người này để MyPostsView load đúng list
                    NavigationLink(destination: MyPostsView(
                        uid: userId,
                        scrollToPostId: post.id
                    )) {
                        GeometryReader { geo in
                            Base64ImageView(base64String: firstBase64String)
                                .scaledToFill()
                                .frame(width: geo.size.width, height: geo.size.width)
                                .clipped()
                        }
                        .aspectRatio(1, contentMode: .fit)
                        .overlay(
                            Group {
                                if post.imageUrls.count > 1 {
                                    Image(systemName: "square.fill.on.square.fill")
                                        .font(.caption).foregroundColor(.white)
                                        .padding(8).shadow(radius: 2)
                                }
                            }, alignment: .topTrailing
                        )
                    }
                }
            }
        }
    }
}
