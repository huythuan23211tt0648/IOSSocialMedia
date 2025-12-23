//
//  MyPostsView.swift
//  IOSSocialMedia
//
//  Created on 14/12/25.
//

import SwiftUI
import FirebaseAuth

struct MyPostsView: View {
    let uid: String
    var scrollToPostId: String? = nil // ID bài viết cần cuộn tới
    
    @ObservedObject var postService = PostService.shared
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground).ignoresSafeArea()
            
            if isLoading && postService.posts.isEmpty { // Chỉ hiện loading nếu chưa có bài nào
                ProgressView("Đang tải...")
            } else if postService.posts.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "camera")
                        .font(.system(size: 60))
                        .foregroundColor(.gray.opacity(0.5))
                    Text("Chưa có bài viết nào")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
            } else {
                // 1. ScrollViewReader
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(postService.posts) { post in
                                VStack(spacing: 0) {
                                    MyPostRowView(post: post, onDeleteSuccess: {
                                        if let index = postService.posts.firstIndex(where: { $0.id == post.id }) {
                                            withAnimation {
                                                _ = postService.posts.remove(at: index)
                                            }
                                        }
                                    })
                                    Divider()
                                }
                                .padding(.bottom, 15)
                                // 2. QUAN TRỌNG: Gán ID cho View.
                                // Dùng ID này để proxy tìm thấy vị trí
                                .id(post.id)
                            }
                        }
                    }
                    // 3. Xử lý logic Scroll
                    .onAppear {
                        // Trường hợp 1: Data đã có sẵn (không cần load mạng), scroll ngay
                        if !postService.posts.isEmpty {
                            performScroll(proxy: proxy)
                        }
                        // Vẫn gọi fetch để update mới nhất
                        Task { await fetchPosts() }
                    }
                    // Trường hợp 2: Sau khi load mạng xong
                    .onChange(of: isLoading) { loading in
                        if !loading {
                            performScroll(proxy: proxy)
                        }
                    }
                    // Trường hợp 3: Đề phòng số lượng bài viết thay đổi
                    .onChange(of: postService.posts.count) { _ in
                        performScroll(proxy: proxy)
                    }
                }
            }
        }
        .navigationTitle("Bài viết")
        .navigationBarTitleDisplayMode(.inline)
        // 👇👇👇 THÊM ĐOẠN NÀY VÀO ĐÂY 👇👇👇
        .navigationBarHidden(false)
        // 1. Ẩn TabBar khi vào màn hình này
        .background(
            TabBarAccessor { tabBar in
                tabBar.isHidden = true
            }
        )
        // 2. Hiện lại TabBar khi thoát ra (để không mất TabBar ở các màn hình khác)
        .onDisappear {
            let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
            let root = windowScene?.windows.first?.rootViewController
            
            // Cách 1: Tìm xem Root có phải là TabBarController không
            if let tabBarController = root as? UITabBarController {
                tabBarController.tabBar.isHidden = false
            }
            // Cách 2: (Trường hợp phổ biến của SwiftUI) Tìm trong các con của Root
            else {
                // Duyệt qua các view con để tìm TabBarController
                if let tabBarController = root?.children.first(where: { $0 is UITabBarController }) as? UITabBarController {
                    tabBarController.tabBar.isHidden = false
                }
            }
        }
    }
    
    // --- HÀM SCROLL RIÊNG ---
    func performScroll(proxy: ScrollViewProxy) {
        guard let targetId = scrollToPostId else { return }
        
        // Delay 0.5 giây: Đủ lâu để màn hình chuyển cảnh xong và View được vẽ ra
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.3)) {
                proxy.scrollTo(targetId, anchor: .top) // .top để bài viết nhảy lên đầu màn hình
            }
            
            // Mẹo: Reset lại scrollToPostId để tránh scroll lung tung nếu refresh
            // (Tuỳ chọn, nếu muốn giữ vị trí thì bỏ dòng dưới)
            // scrollToPostId = nil
        }
    }
    
    func fetchPosts() async {
        // Nếu đã có data rồi thì không set isLoading = true để tránh nháy màn hình
        if postService.posts.isEmpty {
            isLoading = true
        }
        await postService.fetchUserPosts(uid: uid)
        await MainActor.run { isLoading = false }
    }
}

// MARK: - ROW VIEW (Giữ nguyên không thay đổi)
import SwiftUI
import FirebaseAuth

struct MyPostRowView: View {
    let post: Post
    var onDeleteSuccess: (() -> Void)?
    
    // --- STATE QUẢN LÝ DỮ LIỆU HIỂN THỊ (OPTIMISTIC UI) ---
    // Dùng biến này để hiển thị thay cho post gốc, giúp UI cập nhật ngay khi sửa xong
    @State private var displayCaption: String = ""
    @State private var displayImages: [String] = []
    
    // --- STATE UI & LOGIC ---
    @State private var isLike = false
    @State private var likeCount = 0
    @State private var showComments = false
    @State private var isProcessing = false
    @State private var showDeleteAlert = false
    @State private var isDeleting = false
    
    // State cho chức năng Edit
    @State private var showEditSheet = false
    
    // State cho Carousel ảnh
    @State private var currentImageIndex = 0
    
    var body: some View {
        VStack(alignment: .leading) {
            
            // MARK: 1. HEADER (Avatar + Username + Menu)
            HStack {
                // Avatar
                if let base64String = post.ownerImageUrl, !base64String.isEmpty {
                    Base64ImageView(base64String: base64String)
                        .scaledToFill()
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 36, height: 36)
                        .foregroundColor(.gray)
                }
                
                // Username
                Text(post.ownerUsername)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // MENU (Chỉ hiện nếu là bài của mình)
                if post.ownerUid == Auth.auth().currentUser?.uid {
                    Menu {
                        // Nút Chỉnh sửa
                        Button {
                            showEditSheet = true
                        } label: {
                            Label("Chỉnh sửa", systemImage: "pencil")
                        }
                        
                        // Nút Xóa
                        Button(role: .destructive) {
                            showDeleteAlert = true
                        } label: {
                            Label("Xóa bài viết", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.primary)
                            .padding(10)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // MARK: 2. IMAGE CAROUSEL (Hiển thị nhiều ảnh)
            // Sử dụng displayImages để hiển thị (cập nhật được khi sửa)
            if !displayImages.isEmpty {
                ZStack(alignment: .topTrailing) {
                    // TabView vuốt ảnh
                    TabView(selection: $currentImageIndex) {
                        ForEach(Array(displayImages.enumerated()), id: \.offset) { index, base64String in
                            Base64ImageView(base64String: base64String)
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .clipped()
                                .tag(index) // Tag để tracking trang hiện tại
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never)) // Tắt chấm mặc định
                    .frame(height: 400)
                    .background(Color.gray.opacity(0.1))
                    
                    // Bộ đếm số trang (1/3) - Chỉ hiện nếu > 1 ảnh
                    if displayImages.count > 1 {
                        Text("\(currentImageIndex + 1)/\(displayImages.count)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Capsule())
                            .padding(12)
                    }
                }
                .frame(height: 400)
            } else {
                // Placeholder nếu không có ảnh (hoặc xóa hết ảnh)
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 200) // Thu nhỏ lại nếu không có ảnh
                    .overlay(Text("Không có ảnh").foregroundColor(.gray))
            }
            
            // MARK: 3. ACTION BUTTONS
            HStack(spacing: 16) {
                // Like Button
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                        isLike.toggle()
                        likeCount += isLike ? 1 : -1
                        handleLikeTapped()
                    }
                }) {
                    Image(systemName: isLike ? "heart.fill" : "heart")
                        .font(.title2)
                        .foregroundColor(isLike ? .red : .primary)
                        .scaleEffect(isLike ? 1.1 : 1.0)
                }
                
                // Comment Button
                Button(action: { showComments = true }) {
                    Image(systemName: "bubble.right")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
                
                Image(systemName: "paperplane")
                    .font(.title2)
                
                Spacer()
                
                // Dots Indicator (Chấm tròn bên dưới)
                if displayImages.count > 1 {
                    HStack(spacing: 4) {
                        ForEach(0..<displayImages.count, id: \.self) { index in
                            Circle()
                                .fill(currentImageIndex == index ? Color.blue : Color.gray.opacity(0.5))
                                .frame(width: 6, height: 6)
                        }
                    }
                    .padding(.leading, -20) // Cân giữa lại chút do Spacer bên trái
                }
                
                Spacer()
                
                Image(systemName: "bookmark")
                    .font(.title2)
            }
            .padding(.horizontal)
            .padding(.top, 4)
            
            // MARK: 4. INFO & CAPTION
            if likeCount > 0 {
                Text("\(likeCount) lượt thích")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.horizontal)
                    .padding(.top, 1)
            }
            
            // Caption (Dùng displayCaption để cập nhật khi sửa)
            HStack(alignment: .top) {
                Text(post.ownerUsername).fontWeight(.semibold) +
                Text(" ") +
                Text(displayCaption) // ✅ Biến này thay đổi ngay khi Edit xong
            }
            .font(.subheadline)
            .padding(.horizontal)
            .padding(.top, 1)

            if let date = post.timestamp {
                Text(timeAgoString(from: date))
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                    .padding(.top, 1)
            }
        }
        .padding(.bottom, 10)
        
        // --- CÁC MODIFIER XỬ LÝ LOGIC ---
        
        // 1. Khởi tạo dữ liệu khi View hiện ra
        .onAppear {
            likeCount = post.likesCount
            // Nạp dữ liệu gốc vào biến hiển thị
            if displayCaption.isEmpty { displayCaption = post.caption }
            if displayImages.isEmpty { displayImages = post.imageUrls }
        }
        
        // 2. Check like status từ server
        .task {
            await checkLikeStatus()
        }
        
        // 3. Sheet Bình luận
        .sheet(isPresented: $showComments) {
            if let postId = post.id {
                CommentsUserView(postId: postId)
            }
        }
        
        // 4. Sheet Chỉnh sửa (Edit)
        .sheet(isPresented: $showEditSheet) {
            // Gọi View Edit mà chúng ta đã tạo ở bước trước
            EditPostView(post: post) { newCaption, newImages in
                // 👇 CALLBACK: Chạy khi bấm Lưu thành công
                // Cập nhật UI ngay lập tức
                self.displayCaption = newCaption
                
                if let newImages = newImages {
                    self.displayImages = newImages
                    self.currentImageIndex = 0 // Reset về ảnh đầu tiên để tránh lỗi index
                }
            }
        }
        
        // 5. Alert Xóa bài
        .alert("Xóa bài viết?", isPresented: $showDeleteAlert) {
            Button("Hủy", role: .cancel) {}
            Button("Xóa", role: .destructive) {
                performDelete()
            }
        } message: {
            Text("Bạn có chắc chắn muốn xóa bài viết này không?")
        }
    }
    
    // MARK: - LOGIC FUNCTIONS
    
    func performDelete() {
        guard let postId = post.id else { return }
        isDeleting = true
        Task {
            do {
                try await PostService.shared.deletePost(postId: postId)
                await MainActor.run {
                    isDeleting = false
                    onDeleteSuccess?() // Báo cho View cha xóa row này đi
                }
            } catch {
                print("Lỗi xóa bài: \(error)")
                await MainActor.run { isDeleting = false }
            }
        }
    }
    
    func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    func checkLikeStatus() async {
        guard let postId = post.id else { return }
        do {
            let didLike = try await PostService.shared.checkIfUserLikedPost(postId: postId)
            withAnimation { self.isLike = didLike }
        } catch { print("Check like error: \(error)") }
    }
    
    func handleLikeTapped() {
        guard !isProcessing else { return }
        isProcessing = true
        Task {
            do {
                try await PostService.shared.likePost(post: post)
                isProcessing = false
            } catch { isProcessing = false }
        }
    }
}
