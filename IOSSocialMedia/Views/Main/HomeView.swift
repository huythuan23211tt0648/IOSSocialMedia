import SwiftUI
import Firebase
import FirebaseAuth

struct HomeView: View {
    @StateObject var viewModel = HomeViewModel()
    @Binding var selectedTab: Int
    var body: some View {
        
        ZStack{
            
            // doi mau tu dong
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing : 0){
                HeaderView()
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
//                        StoryView() // Thêm Story vào cho đẹp
                        Divider()
                        // 👇 LOGIC HIỂN THỊ BÀI VIẾT
                        if viewModel.isLoading && viewModel.posts.isEmpty {
                            ProgressView("Đang tải...")
                                .padding(.top, 50)
                                .frame(maxWidth: .infinity)
                        } else {
                            // Loop qua danh sách bài viết thật
                            ForEach(viewModel.posts) { post in
                                PostView(post: post,selectedTab: $selectedTab) // Truyền object Post vào
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
        @State private var showCreatePost = false
//        @Binding var selectedTab: Int
        var body: some View {
     
            HStack {
                Group{
                    Button(action: {
                                        showCreatePost = true
                                    }) {
                                        Image(systemName: "plus.app")
                                            .font(.title2)
                                            .foregroundColor(.primary)
                                    }
                  
                    // 2. Thêm spacing để các icon không dính nhau
                    Text("Instagram")
                        .font(Font.custom("Billabong", size: 24)) // Hoặc dùng .system nếu không có font
                     
                  
                }.padding(.leading , 20)
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
                
            }// 3. Gắn modifier fullScreenCover vào đây
            .fullScreenCover(isPresented: $showCreatePost) {
                CreatePostView()
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
    let post: Post
    @Binding var selectedTab: Int
    @State private var isLike = false
    @State private var likeCount = 0
    @State private var showEditProfile = false
    @State private var isProcessing = false
    
    // Thêm state để theo dõi trang hiện tại của ảnh
    @State private var currentImageIndex = 0
    
    var body: some View {
        VStack(alignment: .leading) {
            
            // MARK: Header
            HStack {
                if post.ownerUid == Auth.auth().currentUser?.uid {
                        // TRƯỜNG HỢP 1: BÀI CỦA MÌNH -> DÙNG BUTTON
                        Button(action: {
                            selectedTab = 2 // Chỉ cần chuyển Tab là đủ
                        }) {
                            AvatarImage(url: post.ownerImageUrl) // Helper view cho gọn
                        }
                    } else {
                        // TRƯỜNG HỢP 2: BÀI NGƯỜI KHÁC -> DÙNG NAVIGATION LINK
                        NavigationLink(destination: OtherUserProfileView(uid: post.ownerUid)) {
                            AvatarImage(url: post.ownerImageUrl)
                        }
                    }
                Text(post.ownerUsername)
                    .font(.subheadline) // Đổi thành subheadline cho chuẩn hơn
                    .fontWeight(.semibold)
                
                Spacer()
                
                Image(systemName: "ellipsis")
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // MARK: Image Carousel (Vuốt ngang nhiều ảnh)
            // Logic: Nếu có ảnh
            if !post.imageUrls.isEmpty {
                ZStack(alignment: .topTrailing) {
                    // 1. TabView để vuốt ảnh
                    TabView(selection: $currentImageIndex) {
                        ForEach(Array(post.imageUrls.enumerated()), id: \.offset) { index, base64String in
                            Base64ImageView(base64String: base64String)
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .clipped()
                                .tag(index) // Quan trọng để biết đang ở ảnh nào
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never)) // Tắt chấm tròn mặc định
                    .frame(height: 400) // Chiều cao ảnh
                    .background(Color.gray.opacity(0.1))
                    
                    // 2. Chỉ báo số trang (Indicator) - Chỉ hiện nếu có nhiều hơn 1 ảnh
                    if post.imageUrls.count > 1 {
                        Text("\(currentImageIndex + 1)/\(post.imageUrls.count)")
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
                .frame(height: 400) // Khung bao ngoài cũng phải set height
            } else {
                // Trường hợp không có ảnh (Placeholder)
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 400)
                    .overlay(
                        Text("Không có ảnh")
                            .foregroundColor(.gray)
                    )
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
                
                // Hiển thị các chấm tròn (Dots Indicator) nếu muốn ở dưới
                if post.imageUrls.count > 1 {
                    HStack(spacing: 4) {
                        ForEach(0..<post.imageUrls.count, id: \.self) { index in
                            Circle()
                                .fill(currentImageIndex == index ? Color.blue : Color.gray.opacity(0.5))
                                .frame(width: 6, height: 6)
                        }
                    }
                    // Cân giữa các chấm
                    .padding(.leading, -20) // Trick nhỏ để bù lại Spacer bên trái nếu cần
                }
                
                Spacer()
                
                Image(systemName: "bookmark")
                    .font(.title2)
            }
            .padding(.horizontal)
            .padding(.top, 4)
            
            // ... Phần bên dưới giữ nguyên (Likes count, Caption, Time ago...)
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
        .sheet(isPresented: $showEditProfile) {
            if let postId = post.id {
                 // CommentsUserView(postId: postId) // Uncomment khi dùng thật
                 Text("Màn hình bình luận cho bài: \(postId)")
            }
        }
        .task {
                    await checkLikeStatus()
                }
        .onAppear {
            likeCount = post.likesCount
            // Check like status here
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
    

    
// MARK: AVAtar
struct AvatarImage: View {
    let url: String?
    var body: some View {
        if let base64String = url, !base64String.isEmpty {
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
