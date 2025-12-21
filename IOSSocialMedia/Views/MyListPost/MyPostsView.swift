//
//  MyPostsView.swift
//  IOSSocialMedia
//
//  Created on 14/12/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseAuth

// MARK: - Mock User Helper (for testing)
extension Auth {
    static var mockUserId: String {
        return "test_user_123"
    }
    
    static var mockUsername: String {
        return "test_user"
    }
    
    static var currentUserIdForTesting: String? {
        #if DEBUG
        // Trả về user giả nếu chưa đăng nhập (cho testing)
        if let realUserId = Auth.auth().currentUser?.uid {
            return realUserId
        } else {
            return mockUserId
        }
        #else
        return Auth.auth().currentUser?.uid
        #endif
    }
    
    static var currentUsernameForTesting: String {
        #if DEBUG
        // Trả về username giả nếu chưa đăng nhập (cho testing)
        if let realUser = Auth.auth().currentUser {
            return realUser.displayName ?? realUser.email?.components(separatedBy: "@").first ?? "User"
        } else {
            return mockUsername
        }
        #else
        let user = Auth.auth().currentUser
        return user?.displayName ?? user?.email?.components(separatedBy: "@").first ?? "User"
        #endif
    }
}

struct MyPostsView: View {
    @State private var posts: [Post] = []
    @State private var isLoading = false
    @State private var selectedPostIndex: Int?
    @State private var showPostDetail = false
    
    // Cho phép truyền posts từ bên ngoài (dùng cho preview)
    var previewPosts: [Post]? = nil
    
    // Flag để dùng sample data khi chạy app thật (development mode)
    var useSampleData: Bool = false
    
    // Grid 3 cột, khoảng cách 1px giống Instagram
    let columns = [
        GridItem(.flexible(), spacing: 1),
        GridItem(.flexible(), spacing: 1),
        GridItem(.flexible(), spacing: 1)
    ]
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            if isLoading && posts.isEmpty {
                ProgressView()
                    .scaleEffect(1.5)
            } else if posts.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 60))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("Chưa có bài viết nào")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 1) {
                        ForEach(Array(posts.enumerated()), id: \.element.id) { index, post in
                            PostGridItemView(post: post)
                                .onTapGesture {
                                    selectedPostIndex = index
                                    showPostDetail = true
                                }
                        }
                    }
                }
            }
        }
        .onAppear {
            if let previewPosts = previewPosts {
                // Dùng dữ liệu preview nếu có
                posts = previewPosts
            } else if useSampleData {
                // Dùng sample data nếu được bật (cho development)
                posts = Post.samplePosts
            } else {
                // Fetch từ Firestore
                fetchMyPosts()
            }
        }
        .fullScreenCover(isPresented: $showPostDetail) {
            if let startIndex = selectedPostIndex, !posts.isEmpty {
                PostsDetailView(
                    posts: posts,
                    startIndex: startIndex,
                    isPresented: $showPostDetail,
                    onPostDeleted: { postId in
                        // Xóa bài viết khỏi danh sách
                        posts.removeAll { $0.id == postId }
                    }
                )
            } else {
                // Fallback nếu có lỗi
                ZStack {
                    Color.black.ignoresSafeArea()
                    VStack {
                        Text("Không thể tải bài viết")
                            .foregroundColor(.white)
                        Button("Đóng") {
                            showPostDetail = false
                        }
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
    
    // MARK: - Fetch Posts từ Firestore
    func fetchMyPosts() {
        isLoading = true
        
        // TODO: Thay đổi ownerUid thành UID của user hiện tại
        // Ví dụ: let currentUserId = Auth.auth().currentUser?.uid ?? ""
        let db = Firestore.firestore()
        
        db.collection("posts")
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { querySnapshot, error in
                DispatchQueue.main.async {
                    isLoading = false
                    
                    if let error = error {
                        print("❌ Error fetching posts: \(error.localizedDescription)")
                        // Nếu có lỗi và đang trong development, có thể dùng sample data
                        #if DEBUG
                        print("⚠️ Using sample data due to Firestore error (DEBUG mode)")
                        posts = Post.samplePosts
                        #endif
                        return
                    }
                    
                    guard let documents = querySnapshot?.documents else {
                        print("⚠️ No documents found in Firestore")
                        // Nếu không có dữ liệu và đang trong development, dùng sample data
                        #if DEBUG
                        print("⚠️ Using sample data - Firestore is empty (DEBUG mode)")
                        posts = Post.samplePosts
                        #else
                        posts = []
                        #endif
                        return
                    }
                    
                    let fetchedPosts = documents.compactMap { document -> Post? in
                        do {
                            return try document.data(as: Post.self)
                        } catch {
                            print("❌ Error decoding post: \(error.localizedDescription)")
                            return nil
                        }
                    }
                    
                    if fetchedPosts.isEmpty {
                        print("⚠️ No valid posts found after decoding")
                        #if DEBUG
                        print("⚠️ Using sample data - No valid posts (DEBUG mode)")
                        posts = Post.samplePosts
                        #else
                        posts = []
                        #endif
                    } else {
                        print("✅ Loaded \(fetchedPosts.count) posts from Firestore")
                        posts = fetchedPosts
                    }
                }
            }
    }
}

// MARK: - Post Grid Item View
struct PostGridItemView: View {
    let post: Post
    
    // Tạo gradient màu dựa trên ID để mỗi post có màu khác nhau
    private var gradientColors: [Color] {
        let colors: [[Color]] = [
            [.red, .orange],
            [.blue, .purple],
            [.green, .mint],
            [.pink, .purple],
            [.orange, .yellow],
            [.cyan, .blue],
            [.purple, .pink],
            [.yellow, .orange],
            [.mint, .teal],
            [.indigo, .purple],
            [.red, .pink],
            [.blue, .cyan],
            [.green, .blue],
            [.orange, .red],
            [.purple, .indigo]
        ]
        let index = abs(post.id?.hashValue ?? 0) % colors.count
        return colors[index]
    }
    
    var body: some View {
        ZStack {
            // Placeholder hoặc ảnh đầu tiên
            if let firstImageUrl = post.imageUrls.first, !firstImageUrl.isEmpty {
                AsyncImage(url: URL(string: firstImageUrl)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(
                                LinearGradient(
                                    colors: gradientColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                // Gradient placeholder nếu không có ảnh (cho preview đẹp hơn)
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay(
                    // Icon nhỏ ở giữa
                    Image(systemName: "photo.fill")
                        .foregroundColor(.white.opacity(0.3))
                        .font(.title3)
                )
            }
            
            // Icon overlay nếu có nhiều ảnh
            if post.imageUrls.count > 1 {
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "square.on.square")
                            .foregroundColor(.white)
                            .font(.caption)
                            .padding(5)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding(5)
            }
            
            // Play button nếu là video (có thể thêm field isVideo vào Post model)
            // Tạm thời comment lại
            // if post.isVideo {
            //     Image(systemName: "play.fill")
            //         .foregroundColor(.white)
            //         .font(.title2)
            //         .padding(8)
            //         .background(Color.black.opacity(0.6))
            //         .clipShape(Circle())
            // }
        }
        .aspectRatio(1, contentMode: .fill)
        .clipped()
    }
}

// MARK: - Posts Detail View (Vuốt giữa các bài viết như Instagram)
struct PostsDetailView: View {
    @State private var posts: [Post]
    let startIndex: Int
    @Binding var isPresented: Bool
    var onPostDeleted: ((String) -> Void)? = nil // Callback khi xóa bài viết
    @State private var currentIndex: Int
    
    init(posts: [Post], startIndex: Int, isPresented: Binding<Bool>, onPostDeleted: ((String) -> Void)? = nil) {
        self._posts = State(initialValue: posts)
        self.startIndex = startIndex
        self._isPresented = isPresented
        self.onPostDeleted = onPostDeleted
        self._currentIndex = State(initialValue: startIndex)
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            GeometryReader { geometry in
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(posts.enumerated()), id: \.element.id) { index, post in
                                PostDetailViewWrapper(
                                    post: Binding(
                                        get: { posts[index] },
                                        set: { posts[index] = $0 }
                                    ),
                                    canDismiss: true,
                                    onDismiss: {
                                        isPresented = false
                                    },
                                    onDelete: { postId in
                                        handlePostDeleted(postId: postId)
                                    },
                                    onPostUpdated: { updatedPost in
                                        // Update post in list
                                        if let index = posts.firstIndex(where: { $0.id == updatedPost.id }) {
                                            posts[index] = updatedPost
                                        }
                                    }
                                )
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .id(index)
                            }
                        }
                    }
                    .onAppear {
                        // Scroll đến bài viết được chọn
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo(startIndex, anchor: .top)
                            }
                            currentIndex = startIndex
                        }
                    }
                }
            }
            
            // Back button ở góc trên trái
            VStack {
                HStack {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding(.leading, 16)
                    .padding(.top, 8)
                    
                    Spacer()
                }
                Spacer()
            }
        }
    }
    
    // MARK: - Handle Post Deleted
    private func handlePostDeleted(postId: String) {
        // Xóa bài viết khỏi danh sách
        posts.removeAll { $0.id == postId }
        
        // Gọi callback để refresh danh sách ở MyPostsView
        onPostDeleted?(postId)
        
        // Nếu không còn bài viết nào, đóng màn hình
        if posts.isEmpty {
            isPresented = false
        } else {
            // Điều chỉnh currentIndex nếu cần
            if currentIndex >= posts.count {
                currentIndex = max(0, posts.count - 1)
            }
        }
    }
}

// MARK: - Post Detail View Wrapper
struct PostDetailViewWrapper: View {
    @Binding var post: Post
    var canDismiss: Bool = false
    var onDismiss: (() -> Void)? = nil
    var onDelete: ((String) -> Void)? = nil
    var onPostUpdated: ((Post) -> Void)? = nil
    
    var body: some View {
        PostDetailView(
            post: $post,
            canDismiss: canDismiss,
            onDismiss: onDismiss,
            onDelete: onDelete,
            onPostUpdated: onPostUpdated
        )
    }
}

// MARK: - Post Detail View (Khi click vào bài viết)
struct PostDetailView: View {
    @Binding var post: Post // Đổi thành @Binding để có thể update từ parent
    var canDismiss: Bool = false
    var onDismiss: (() -> Void)? = nil
    var onDelete: ((String) -> Void)? = nil // Callback khi xóa bài viết
    var onPostUpdated: ((Post) -> Void)? = nil // Callback khi post được update (like, comment)
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var showMenu = false
    @State private var showDeleteAlert = false
    @State private var isDeleting = false
    @State private var isLiked = false
    @State private var isLiking = false
    @State private var showComments = false
    @State private var comments: [Comment] = []
    @State private var isLoadingComments = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // MARK: - Header
                    HStack {
                        // Avatar
                        if let imageUrl = post.ownerImageUrl, !imageUrl.isEmpty {
                            AsyncImage(url: URL(string: imageUrl)) { phase in
                                if case .success(let image) = phase {
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } else {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                }
                            }
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.gray)
                        }
                        
                        Text(post.ownerUsername)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Menu button với action sheet
                        Button(action: {
                            showMenu = true
                        }) {
                            Image(systemName: "ellipsis")
                                .foregroundColor(.white)
                        }
                        .confirmationDialog("Tùy chọn", isPresented: $showMenu, titleVisibility: .visible) {
                            Button("Xóa bài viết", role: .destructive) {
                                showDeleteAlert = true
                            }
                            Button("Hủy", role: .cancel) { }
                        }
                    }
                    .padding()
                    .background(Color.black)
                    
                    // MARK: - Images
                    let imageHeight = UIScreen.main.bounds.width
                    if !post.imageUrls.isEmpty {
                        TabView {
                            ForEach(post.imageUrls, id: \.self) { imageUrl in
                                AsyncImage(url: URL(string: imageUrl)) { phase in
                                    switch phase {
                                    case .empty:
                                        ZStack {
                                            Color.black
                                            ProgressView()
                                                .tint(.white)
                                        }
                                        .frame(height: imageHeight)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFit()
                                            .frame(maxHeight: imageHeight)
                                    case .failure:
                                        ZStack {
                                            Color.black
                                            Image(systemName: "photo")
                                                .foregroundColor(.gray)
                                        }
                                        .frame(height: imageHeight)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                            }
                        }
                        .frame(height: imageHeight)
                        .tabViewStyle(PageTabViewStyle())
                    } else {
                        // Gradient placeholder nếu không có ảnh
                        let gradientColors = getGradientColors(for: post)
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(height: imageHeight)
                    }
                    
                    // MARK: - Action Buttons
                    HStack(spacing: 20) {
                        // Like button
                        Button(action: {
                            toggleLike()
                        }) {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .font(.title2)
                                .foregroundColor(isLiked ? .red : .white)
                        }
                        .disabled(isLiking)
                        
                        // Comment button
                        Button(action: {
                            showComments = true
                        }) {
                            Image(systemName: "bubble.right")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                        
                        // Share button
                        Button(action: {
                            // TODO: Implement share
                        }) {
                            Image(systemName: "paperplane")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        // Bookmark button
                        Button(action: {
                            // TODO: Implement bookmark
                        }) {
                            Image(systemName: "bookmark")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                    .background(Color.black)
                    
                    // MARK: - Likes Count
                    Text("\(post.likesCount) lượt thích")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .background(Color.black)
                    
                    // MARK: - Caption
                    HStack(alignment: .top) {
                        Text(post.ownerUsername)
                            .font(.headline)
                            .foregroundColor(.white)
                        + Text(" \(post.caption)")
                            .font(.body)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)
                    .background(Color.black)
                    
                    // MARK: - Comments
                    if post.commentsCount > 0 {
                        Button {
                            showComments = true
                        } label: {
                            Text("Xem tất cả \(post.commentsCount) bình luận")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal)
                        .padding(.top, 4)
                        .background(Color.black)
                    }
                    
                    // MARK: - Timestamp
                    if let timestamp = post.timestamp {
                        Text(timeAgoString(from: timestamp))
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                            .padding(.top, 4)
                            .padding(.bottom, 20)
                            .background(Color.black)
                    } else {
                        Color.black
                            .frame(height: 20)
                    }
                }
            }
            .offset(y: dragOffset)
            .opacity(isDragging ? max(0.5, 1 - abs(dragOffset) / 300.0) : 1)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if canDismiss && value.translation.height > 0 {
                            isDragging = true
                            dragOffset = value.translation.height
                        }
                    }
                    .onEnded { value in
                        if canDismiss && value.translation.height > 150 {
                            // Vuốt xuống đủ xa thì đóng
                            onDismiss?()
                        } else {
                            // Không đủ xa thì quay lại
                            withAnimation(.spring()) {
                                dragOffset = 0
                                isDragging = false
                            }
                        }
                    }
            )
            .alert("Xóa bài viết", isPresented: $showDeleteAlert) {
                Button("Hủy", role: .cancel) { }
                Button("Xóa", role: .destructive) {
                    deletePost()
                }
            } message: {
                Text("Bạn có chắc chắn muốn xóa bài viết này? Hành động này không thể hoàn tác.")
            }
            .overlay {
                if isDeleting || isLiking {
                    ZStack {
                        Color.black.opacity(0.7)
                            .ignoresSafeArea()
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                    }
                }
            }
            .sheet(isPresented: $showComments) {
                if let postId = post.id {
                    CommentsView(postId: postId, post: post, onCommentAdded: { newCommentCount in
                        post.commentsCount = newCommentCount
                        onPostUpdated?(post)
                    })
                }
            }
            .onAppear {
                checkIfLiked()
                loadComments()
            }
        }
    }
    
    // MARK: - Check If Liked
    private func checkIfLiked() {
        guard let postId = post.id,
              let currentUserId = Auth.currentUserIdForTesting else {
            return
        }
        
        let db = Firestore.firestore()
        db.collection("posts")
            .document(postId)
            .collection("likes")
            .document(currentUserId)
            .getDocument { snapshot, error in
                if let snapshot = snapshot, snapshot.exists {
                    isLiked = true
                } else {
                    isLiked = false
                }
            }
    }
    
    // MARK: - Toggle Like
    private func toggleLike() {
        guard let postId = post.id,
              let currentUserId = Auth.currentUserIdForTesting else {
            print("❌ Không thể like: Chưa đăng nhập")
            return
        }
        
        let currentUsername = Auth.currentUsernameForTesting
        
        isLiking = true
        
        Task {
            do {
                try await PostService.likePost(
                    post: post,
                    uid: currentUserId,
                    username: currentUsername
                )
                
                await MainActor.run {
                    isLiking = false
                    isLiked.toggle()
                    
                    // Update likes count
                    if isLiked {
                        post.likesCount += 1
                    } else {
                        post.likesCount = max(0, post.likesCount - 1)
                    }
                    
                    // Notify parent
                    onPostUpdated?(post)
                }
            } catch {
                await MainActor.run {
                    isLiking = false
                    print("❌ Lỗi khi like bài viết: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Load Comments
    private func loadComments() {
        guard let postId = post.id, !postId.isEmpty else { return }
        
        isLoadingComments = true
        
        Task {
            do {
                let fetchedComments = try await PostService.fetchComments(postId: postId)
                await MainActor.run {
                    comments = fetchedComments
                    isLoadingComments = false
                }
            } catch {
                await MainActor.run {
                    isLoadingComments = false
                    print("❌ Lỗi khi load comments: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Delete Post Function
    private func deletePost() {
        guard let postId = post.id else { return }
        
        isDeleting = true
        
        Task {
            do {
                try await PostService.deletePost(postId: postId)
                
                await MainActor.run {
                    isDeleting = false
                    // Gọi callback để xóa bài viết khỏi danh sách
                    onDelete?(postId)
                    // Đóng màn hình sau khi xóa
                    onDismiss?()
                }
            } catch {
                await MainActor.run {
                    isDeleting = false
                    print("❌ Lỗi khi xóa bài viết: \(error.localizedDescription)")
                    // Có thể thêm alert lỗi ở đây nếu cần
                }
            }
        }
    }
    
    private func getGradientColors(for post: Post) -> [Color] {
        let colors: [[Color]] = [
            [.red, .orange],
            [.blue, .purple],
            [.green, .mint],
            [.pink, .purple],
            [.orange, .yellow],
            [.cyan, .blue],
            [.purple, .pink],
            [.yellow, .orange],
            [.mint, .teal],
            [.indigo, .purple],
            [.red, .pink],
            [.blue, .cyan],
            [.green, .blue],
            [.orange, .red],
            [.purple, .indigo]
        ]
        let index = abs(post.id?.hashValue ?? 0) % colors.count
        return colors[index]
    }
    
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Sample Data
extension Post {
    static var samplePosts: [Post] {
        [
            Post(
                id: "1",
                ownerUid: "user1",
                ownerUsername: "ai_ma_biet_duoc",
                ownerImageUrl: nil,
                caption: "Cuối tuần vui vẻ! 🌞 #weekend #vietnam",
                imageUrls: [],
                likesCount: 158,
                commentsCount: 12,
                timestamp: Date().addingTimeInterval(-3600)
            ),
            Post(
                id: "2",
                ownerUid: "user1",
                ownerUsername: "ai_ma_biet_duoc",
                ownerImageUrl: nil,
                caption: "Bữa sáng ngon lành ☕️",
                imageUrls: [],
                likesCount: 89,
                commentsCount: 5,
                timestamp: Date().addingTimeInterval(-7200)
            ),
            Post(
                id: "3",
                ownerUid: "user1",
                ownerUsername: "ai_ma_biet_duoc",
                ownerImageUrl: nil,
                caption: "Sunset vibes 🌅",
                imageUrls: [],
                likesCount: 234,
                commentsCount: 18,
                timestamp: Date().addingTimeInterval(-10800)
            ),
            Post(
                id: "4",
                ownerUid: "user1",
                ownerUsername: "ai_ma_biet_duoc",
                ownerImageUrl: nil,
                caption: "Coffee time ☕️",
                imageUrls: [],
                likesCount: 67,
                commentsCount: 3,
                timestamp: Date().addingTimeInterval(-14400)
            ),
            Post(
                id: "5",
                ownerUid: "user1",
                ownerUsername: "ai_ma_biet_duoc",
                ownerImageUrl: nil,
                caption: "New day, new energy! 💪",
                imageUrls: [],
                likesCount: 145,
                commentsCount: 9,
                timestamp: Date().addingTimeInterval(-18000)
            ),
            Post(
                id: "6",
                ownerUid: "user1",
                ownerUsername: "ai_ma_biet_duoc",
                ownerImageUrl: nil,
                caption: "Exploring the city 🏙️",
                imageUrls: [],
                likesCount: 312,
                commentsCount: 24,
                timestamp: Date().addingTimeInterval(-21600)
            ),
            Post(
                id: "7",
                ownerUid: "user1",
                ownerUsername: "ai_ma_biet_duoc",
                ownerImageUrl: nil,
                caption: "Foodie moment 🍜",
                imageUrls: [],
                likesCount: 198,
                commentsCount: 15,
                timestamp: Date().addingTimeInterval(-25200)
            ),
            Post(
                id: "8",
                ownerUid: "user1",
                ownerUsername: "ai_ma_biet_duoc",
                ownerImageUrl: nil,
                caption: "Chill vibes only 😎",
                imageUrls: [],
                likesCount: 176,
                commentsCount: 11,
                timestamp: Date().addingTimeInterval(-28800)
            ),
            Post(
                id: "9",
                ownerUid: "user1",
                ownerUsername: "ai_ma_biet_duoc",
                ownerImageUrl: nil,
                caption: "Weekend adventure 🚗",
                imageUrls: [],
                likesCount: 267,
                commentsCount: 19,
                timestamp: Date().addingTimeInterval(-32400)
            ),
            Post(
                id: "10",
                ownerUid: "user1",
                ownerUsername: "ai_ma_biet_duoc",
                ownerImageUrl: nil,
                caption: "Nature is beautiful 🌿",
                imageUrls: [],
                likesCount: 423,
                commentsCount: 32,
                timestamp: Date().addingTimeInterval(-36000)
            ),
            Post(
                id: "11",
                ownerUid: "user1",
                ownerUsername: "ai_ma_biet_duoc",
                ownerImageUrl: nil,
                caption: "Good vibes ✨",
                imageUrls: [],
                likesCount: 134,
                commentsCount: 7,
                timestamp: Date().addingTimeInterval(-39600)
            ),
            Post(
                id: "12",
                ownerUid: "user1",
                ownerUsername: "ai_ma_biet_duoc",
                ownerImageUrl: nil,
                caption: "Making memories 📸",
                imageUrls: [],
                likesCount: 289,
                commentsCount: 21,
                timestamp: Date().addingTimeInterval(-43200)
            ),
            Post(
                id: "13",
                ownerUid: "user1",
                ownerUsername: "ai_ma_biet_duoc",
                ownerImageUrl: nil,
                caption: "Life is good 🎉",
                imageUrls: [],
                likesCount: 156,
                commentsCount: 8,
                timestamp: Date().addingTimeInterval(-46800)
            ),
            Post(
                id: "14",
                ownerUid: "user1",
                ownerUsername: "ai_ma_biet_duoc",
                ownerImageUrl: nil,
                caption: "Sunny day ☀️",
                imageUrls: [],
                likesCount: 201,
                commentsCount: 14,
                timestamp: Date().addingTimeInterval(-50400)
            ),
            Post(
                id: "15",
                ownerUid: "user1",
                ownerUsername: "ai_ma_biet_duoc",
                ownerImageUrl: nil,
                caption: "Happy moments 😊",
                imageUrls: [],
                likesCount: 178,
                commentsCount: 10,
                timestamp: Date().addingTimeInterval(-54000)
            )
        ]
    }
}

// MARK: - Comments View
struct CommentsView: View {
    let postId: String
    @State var post: Post
    var onCommentAdded: ((Int) -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var comments: [Comment] = []
    @State private var isLoading = false
    @State private var commentText = ""
    @State private var isPosting = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Comments list
                if isLoading && comments.isEmpty {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if comments.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "bubble.right")
                            .font(.system(size: 50))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("Chưa có bình luận nào")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 16) {
                            ForEach(comments) { comment in
                                CommentRowView(comment: comment)
                            }
                        }
                        .padding()
                    }
                }
                
                Divider()
                
                // Comment input
                HStack(spacing: 12) {
                    // Avatar
                    if let currentUser = Auth.auth().currentUser,
                       let photoURL = currentUser.photoURL {
                        AsyncImage(url: photoURL) { phase in
                            if case .success(let image) = phase {
                                image
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                            }
                        }
                        .frame(width: 35, height: 35)
                        .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 35, height: 35)
                            .foregroundColor(.gray)
                    }
                    
                    // Text field
                    TextField("Thêm bình luận...", text: $commentText)
                        .textFieldStyle(.roundedBorder)
                    
                    // Send button
                    Button(action: {
                        postComment()
                    }) {
                        if isPosting {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.title2)
                                .foregroundColor(commentText.isEmpty ? .gray : .blue)
                        }
                    }
                    .disabled(commentText.isEmpty || isPosting)
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .navigationTitle("Bình luận")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Đóng") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadComments()
            }
        }
    }
    
    // MARK: - Load Comments
    private func loadComments() {
        guard !postId.isEmpty else { return }
        
        isLoading = true
        
        Task {
            do {
                let fetchedComments = try await PostService.fetchComments(postId: postId)
                await MainActor.run {
                    comments = fetchedComments
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    print("❌ Lỗi khi load comments: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Post Comment
    private func postComment() {
        guard !commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let currentUserId = Auth.currentUserIdForTesting else {
            print("❌ Không thể comment: Chưa đăng nhập hoặc text rỗng")
            return
        }
        
        let currentUsername = Auth.currentUsernameForTesting
        
        isPosting = true
        
        let newComment = Comment(
            id: nil,
            uid: currentUserId,
            username: currentUsername,
            profileImageUrl: Auth.auth().currentUser?.photoURL?.absoluteString,
            text: commentText.trimmingCharacters(in: .whitespacesAndNewlines),
            timestamp: nil
        )
        
        Task {
            do {
                try await PostService.addComment(postId: postId, comment: newComment)
                
                await MainActor.run {
                    isPosting = false
                    commentText = ""
                    
                    // Update comment count
                    post.commentsCount += 1
                    onCommentAdded?(post.commentsCount)
                    
                    // Reload comments
                    loadComments()
                }
            } catch {
                await MainActor.run {
                    isPosting = false
                    print("❌ Lỗi khi thêm comment: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Comment Row View
struct CommentRowView: View {
    let comment: Comment
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar
            if let imageUrl = comment.profileImageUrl, !imageUrl.isEmpty {
                AsyncImage(url: URL(string: imageUrl)) { phase in
                    if case .success(let image) = phase {
                        image
                            .resizable()
                            .scaledToFill()
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                    }
                }
                .frame(width: 35, height: 35)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 35, height: 35)
                    .foregroundColor(.gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(comment.username)
                        .font(.headline)
                    if let timestamp = comment.timestamp {
                        Text(timeAgoString(from: timestamp))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Text(comment.text)
                    .font(.body)
            }
            
            Spacer()
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Preview
struct MyPostsView_Previews: PreviewProvider {
    static var previews: some View {
        MyPostsView(previewPosts: Post.samplePosts)
            .previewDisplayName("My Posts Grid")
        
        // Preview cho PostsDetailView (vuốt giữa các bài viết)
        PostsDetailView(
            posts: Post.samplePosts,
            startIndex: 0,
            isPresented: .constant(true)
        )
        .previewDisplayName("Posts Detail (Swipe)")
        
        // Preview cho PostDetailView đơn lẻ
        PostDetailViewWrapper(
            post: .constant(Post.samplePosts[0]),
            canDismiss: true
        )
        .previewDisplayName("Post Detail Single")
    }
}

