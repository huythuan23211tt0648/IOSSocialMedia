import SwiftUI

struct HomeView: View {
    @StateObject var viewModel = HomeViewModel()
    var body: some View {
        
        ZStack{
            
            // doi mau tu dong
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing : 0){
                HeaderView()
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        StoryView() // Thêm Story vào cho đẹp
                        Divider()
                        // 👇 LOGIC HIỂN THỊ BÀI VIẾT
                        if viewModel.isLoading && viewModel.posts.isEmpty {
                            ProgressView("Đang tải...")
                                .padding(.top, 50)
                                .frame(maxWidth: .infinity)
                        } else {
                            // Loop qua danh sách bài viết thật
                            ForEach(viewModel.posts) { post in
                                PostView(post: post) // Truyền object Post vào
                            }
                        }
                        
                    }
                    // 👇 Tự động tải lại khi kéo xuống
                    .refreshable {
                        await viewModel.loadPosts()
                    }
                }
                
                
                
                
                
            }.navigationTitle("")
                .navigationBarBackButtonHidden(true)
                .task {
                    await viewModel.loadPosts()
                }
        }
        
    }
    
    struct HeaderView:View {
        var body: some View {
            
            HStack { // 2. Thêm spacing để các icon không dính nhau
                Text("Instagram")
                    .font(Font.custom("Billabong", size: 24)) // Hoặc dùng .system nếu không có font
                    .padding(.leading, 20)
                Spacer()
                
                //                Image(systemName: "camera")
                //                    .font(.title2)
                
                
                // 3. THÊM LOGO/CHỮ VÀO ĐÂY (Trong phần leading)
                Group{
                    Image(systemName: "heart")
                        .font(.title2)
                    Image(systemName: "paperplane")
                        .font(.title2)
                }
                .padding(.trailing, 20)
                
            }
            
            
            
            
        }
    }
    
    // MARK: Stories
    struct StoryView:View {
        var body: some View {
            
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
            
            
        }
    }
}
    //MARK: POST VIEW
 struct PostView: View {
        // 👇 Thay đổi: Nhận toàn bộ object Post
        let post: Post
        
        @State private var isLike = false
        @State private var likeCount = 0
        @State private var showEditProfile = false
        // Để tránh spam nút like liên tục
        @State private var isProcessing = false
        var body: some View {
            VStack(alignment: .leading) {
                
                // MARK: Header
                HStack {
                    // Avatar người đăng (Nếu có url thì load, không thì mặc định)
                    // Kiểm tra xem có dữ liệu ảnh không
                    if let base64String = post.ownerImageUrl, !base64String.isEmpty {
                        Base64ImageView(base64String: base64String)
                            .scaledToFill() // Giữ tỷ lệ ảnh, lấp đầy khung tròn
                            .frame(width: 36, height: 36)
                            .clipShape(Circle())
                    } else {
                        // Ảnh mặc định nếu không có avatar
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .frame(width: 36, height: 36)
                            .clipShape(Circle())
                            .foregroundColor(.gray)
                    }
                    
                    Text(post.ownerUsername) // 👇 Tên người đăng thật
                        .font(.headline)
                        .font(.system(size: 14))
                    
                    Spacer()
                    
                    Image(systemName: "ellipsis")
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // MARK: Image (Hiển thị ảnh Base64)
                // Lấy ảnh đầu tiên trong mảng imageUrls
                if let base64String = post.imageUrls.first {
                    Base64ImageView(base64String: base64String)
                        .frame(height: 400) // Chiều cao chuẩn Instagram
                        .frame(maxWidth: .infinity)
                        .clipped()
                } else {
                    Rectangle().frame(height: 400).foregroundColor(.gray)
                }
                
                // MARK: Action buttons
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
                    
                    Button(action: { showEditProfile = true }) {
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
                
                // MARK: Likes count
                if likeCount > 0 {
                    Text("\(likeCount) lượt thích")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.horizontal)
                        .padding(.top, 1)
                }
                
                // MARK: Caption
                HStack(alignment: .top) {
                    Text(post.ownerUsername).fontWeight(.semibold) +
                    Text(" ") +
                    Text(post.caption) // 👇 Caption thật
                }
                .font(.subheadline)
                .padding(.horizontal)
                .padding(.top, 1)

                // Time ago (Nếu có)
                if let date = post.timestamp {
                    Text(date.toShortTime()) // Dùng extension toShortTime hôm qua mình đưa
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                        .padding(.top, 1)
                }
            }
            .padding(.bottom, 10)
            // Sheet Comment
            .sheet(isPresented: $showEditProfile) {
                // 👇 TRUYỀN POST ID VÀO ĐÂY (Bắt buộc phải có ID mới lấy được comment)
                if let postId = post.id {
                    CommentsUserView(postId: postId)
                } else {
                    Text("Bài viết không tồn tại ID")
                }
            }
            .task {
                await checkLikeStatus()
            }
            // Khởi tạo số lượng like ban đầu từ Post Model
            .onAppear {
                likeCount = post.likesCount
            }
            
        }
        // --- CÁC HÀM XỬ LÝ ---
        
        // 1. Kiểm tra xem user đã like bài này chưa
        func checkLikeStatus() async {
            guard let postId = post.id else { return }
            do {
                let didLike = try await PostService.shared.checkIfUserLikedPost(postId: postId)
                // Cập nhật giao diện
                withAnimation {
                    self.isLike = didLike
                }
            } catch {
                print("Lỗi check like: \(error)")
            }
        }
        
        // 2. Xử lý khi bấm nút Like
        func handleLikeTapped() {
            guard !isProcessing else { return }
            isProcessing = true
            
            // UI Optimistic Update (Cập nhật giao diện giả trước cho mượt)
            let previousState = isLike
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                isLike.toggle()
                likeCount += isLike ? 1 : -1
            }
            
            // Gọi API thật
            Task {
                do {
                    try await PostService.shared.likePost(post: post)
                    isProcessing = false
                } catch {
                    // Nếu lỗi thì hoàn tác lại giao diện cũ
                    print("Lỗi like: \(error)")
                    withAnimation {
                        isLike = previousState
                        likeCount += isLike ? 1 : -1
                    }
                    isProcessing = false
                }
            }
        }
    }
    
    
    
    // MARK: - COMMENTS VIEW (Màn hình danh sách bình luận)
  struct CommentsUserView: View {
            @Environment(\.presentationMode) var presentationMode
            
            // 👇 ViewModel quản lý dữ liệu
            @StateObject var viewModel: CommentViewModel
            
            // 👇 Khởi tạo với Post ID
            init(postId: String) {
                _viewModel = StateObject(wrappedValue: CommentViewModel(postId: postId))
            }
            
            var body: some View {
                VStack(spacing: 0) {
                    // 1. HEADER (Giữ nguyên)
                    HStack {
                        Button(action: { presentationMode.wrappedValue.dismiss() }) {
                            Image(systemName: "arrow.left").font(.title2).foregroundColor(.primary)
                        }
                        Spacer()
                        Text("Bình luận")
                            .font(.headline).fontWeight(.bold)
                        Spacer()
                        Image(systemName: "paperplane").font(.title2).hidden()
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    
                    Divider()
                    
                    // 2. DANH SÁCH COMMENT
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 16) {
                            if viewModel.isLoading {
                                ProgressView().padding(.top, 20)
                            } else if viewModel.comments.isEmpty {
                                Text("Chưa có bình luận nào.")
                                    .foregroundColor(.gray)
                                    .padding(.top, 20)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            } else {
                                // 👇 Loop qua dữ liệu thật từ ViewModel
                                ForEach(viewModel.comments) { comment in
                                    CommentRow(comment: comment)
                                }
                            }
                        }
                        .padding(.top, 10)
                    }
                    
                    // 3. Ô NHẬP LIỆU (Giữ nguyên)
                    CommentInputView(viewModel: viewModel)
                }
                .navigationBarHidden(true)
                
                // 👇👇👇 SỬA ĐOẠN NÀY: Dùng onAppear thay vì task
                .onAppear {
                    print("📢 Màn hình bình luận đã hiện -> Bắt đầu tải data...")
                    Task {
                        await viewModel.loadComments()
                    }
                }
            }
        }
    
    // MARK: - COMMENT INPUT FORM
  struct CommentInputView: View {
        @State private var commentText: String = ""
        @ObservedObject var viewModel: CommentViewModel // 👇 Nhận ViewModel
        
        var body: some View {
            VStack(spacing: 0) {
                Divider()
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.gray)
                    
                    TextField("Thêm bình luận...", text: $commentText)
                        .font(.subheadline)
                        .padding(10)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(20)
                    
                    if !commentText.isEmpty {
                        Button("Đăng") {
                            Task {
                                await viewModel.sendComment(content: commentText)
                                commentText = "" // Xóa text sau khi gửi
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            }
                        }
                        .font(.subheadline.bold())
                        .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
            }
            .background(Color(.systemBackground))
        }
    }
    
    // MARK: COMMENT
    struct CommentRow: View {
        let comment: Comment
        
        var body: some View {
            HStack(alignment: .top, spacing: 12) {
                // 1. Avatar người comment
                // Kiểm tra xem có dữ liệu ảnh không
                if let base64String = comment.profileImageUrl, !base64String.isEmpty {
                    Base64ImageView(base64String: base64String)
                        .scaledToFill() // Giữ tỷ lệ ảnh, lấp đầy khung tròn
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                } else {
                    // Ảnh mặc định nếu không có avatar
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                        .foregroundColor(.gray)
                }
                
                // 2. Nội dung (Tên + Comment + Thông tin phụ)
                VStack(alignment: .leading, spacing: 4) {
                    // Mẹo: Dùng Text + Text để nối chuỗi (Tên đậm, nội dung thường)
                    (Text(comment.username).fontWeight(.bold) + Text("\n") + Text(comment.content))
                        .font(.subheadline)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true) // Cho phép xuống dòng
                    
                    // Dòng phụ: Thời gian - Số lượt thích - Trả lời
                    HStack(spacing: 15) {
                        Text(comment.timestamp?.toShortTime() ?? "vừa xong")
                        if comment.likeCount > 0 {
                            Text("\(comment.likeCount) lượt thích")
                        }
                        Text("Trả lời")
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                }
                
                Spacer()
                
                // 3. Nút tim nhỏ bên phải
                Image(systemName: "heart")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.top, 10)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
    
    
    
    
    
    //    struct HomeView_Previews: PreviewProvider {
    //        static var previews: some View {
    //            HomeView()
    //        }
    //    }
