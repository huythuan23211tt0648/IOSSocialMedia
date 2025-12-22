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
                
                // 1. Ẩn TabBar khi vào màn hình này
                .background(
                    TabBarAccessor { tabBar in
                        tabBar.isHidden = true
                    }
                )
                // 2. Hiện lại TabBar khi thoát ra (để không mất TabBar ở các màn hình khác)
                .onDisappear {
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let tabBarController = windowScene.windows.first?.rootViewController as? UITabBarController {
                        tabBarController.tabBar.isHidden = false
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
struct MyPostRowView: View {
    let post: Post
    var onDeleteSuccess: (() -> Void)?

    @State private var isLike = false
    @State private var likeCount = 0
    @State private var showComments = false
    @State private var isProcessing = false
    @State private var showDeleteAlert = false
    @State private var isDeleting = false
    
    var body: some View {
        VStack(alignment: .leading) {
            
            // --- HEADER ---
            HStack {
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
                
                Text(post.ownerUsername)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                if(post.ownerUid == Auth.auth().currentUser?.uid ){
                    Menu {
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
            
            // --- IMAGE ---
            if let base64String = post.imageUrls.first {
                Base64ImageView(base64String: base64String)
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1, contentMode: .fit)
                    .clipped()
                    .background(Color.gray.opacity(0.1))
            } else {
                Rectangle().frame(height: 400).foregroundColor(.gray.opacity(0.3))
            }
            
            // --- ACTION BUTTONS ---
            HStack(spacing: 16) {
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
                
                Button(action: { showComments = true }) {
                    Image(systemName: "bubble.right")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
                
                Image(systemName: "paperplane")
                    .font(.title2)
                
                Spacer()
                
                Image(systemName: "bookmark")
                    .font(.title2)
            }
            .padding(.horizontal)
            .padding(.top, 4)
            
            // --- INFO ---
            if likeCount > 0 {
                Text("\(likeCount) lượt thích")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.horizontal)
                    .padding(.top, 1)
            }
            
            HStack(alignment: .top) {
                Text(post.ownerUsername).fontWeight(.semibold) +
                Text(" ") +
                Text(post.caption)
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
        .sheet(isPresented: $showComments) {
            if let postId = post.id {
                CommentsUserView(postId: postId)
            }
        }
        .task {
            await checkLikeStatus()
        }
        .onAppear {
            likeCount = post.likesCount
        }
        .alert("Xóa bài viết?", isPresented: $showDeleteAlert) {
            Button("Hủy", role: .cancel) {}
            Button("Xóa", role: .destructive) {
                performDelete()
            }
        } message: {
            Text("Bạn có chắc chắn muốn xóa bài viết này không?")
        }
    }
    
    // Logic functions giữ nguyên
    func performDelete() {
        guard let postId = post.id else { return }
        isDeleting = true
        Task {
            do {
                try await PostService.shared.deletePost(postId: postId)
                await MainActor.run {
                    isDeleting = false
                    onDeleteSuccess?()
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
