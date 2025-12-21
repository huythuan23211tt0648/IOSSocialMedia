import SwiftUI

struct HomeView: View {
    var body: some View {
        ZStack{
            
            // doi mau tu dong
            Color(.systemBackground).ignoresSafeArea()
            
            ScrollView {
                HeaderView()
                VStack(alignment: .leading, spacing: 0) {
                    
                    ForEach(0..<5) { i in
                        PostView(username: "User \(i)")
                    }
                    
                }
            }
            
            
            
            
        }.navigationTitle("")
            .navigationBarBackButtonHidden(true)
    }
}
private struct HeaderView:View {
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
private struct StoryView:View {
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

private struct PostView: View {
    var username: String
    @State private var isLike=false
    @State private var likeCount = 999
    @State private var commentCount = 100
    @State private var showEditProfile = false
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
           
            // MARK: Caption
            VStack(alignment: .leading, spacing: 4) {
                Text("\(username) ")
                    .bold()
                + Text("This is a sample Instagram caption.")
            }
            .padding(.horizontal)
            .padding(.top, 5)
            
            // MARK: Image
            Rectangle()
                .frame(height: 300)
                .foregroundColor(.blue.opacity(0.4))
            
            // MARK: Action buttons
            HStack(spacing: 20) {
                
                Button(action :{
                    withAnimation(.spring(response: 0.3,dampingFraction: 0.5)){
                        isLike.toggle()
                    }
                    if (isLike){
                        likeCount += 1
                    }else{
                        likeCount -= 1
                    }
                    
                }){
                    Image(systemName:isLike ?  "heart.fill": "heart")
                        .font(.title2)
                        .foregroundColor(isLike ? .red : .primary)
                        .scaleEffect(isLike ? 1.2 : 1.0)
                    // Hiển thị số lượng
                    Text("\(likeCount)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                      
                }
          
                
                
                
                Button(action :{
                    withAnimation(.spring(response: 0.3,dampingFraction: 0.5)){
                        showEditProfile=true
                    }
               
                    
                }){
        
                    Image(systemName: "bubble.right")
                        .font(.title2)
                    // Hiển thị số lượng
                    Text("\(commentCount)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }.sheet(isPresented : $showEditProfile){
                    CommentsView()              }
                
          
//                Image(systemName: "paperplane")
//                    .font(.title2)
//                
                Spacer()
                
                Image(systemName: "bookmark")
                    .font(.title2)
            }
            .padding(.horizontal)
            .padding(.vertical, 5)
  
  
        }
            .padding(.vertical, 10)
        
    }
        
}
// MARK: COMMENTView

private struct CommentsUserView: View {
    // Input field cần biến state, nhưng ở đây mình chỉ demo hiển thị
    // Bạn nhớ copy lại struct CommentInputView ở câu trả lời trước vào file này nhé
    @Environment(\.presentationMode) var presentationMode
    var body: some View {
        VStack(spacing: 0) {
            // --- PHẦN 1: HEADER (Thanh tiêu đề) ---
            HStack {
                Image(systemName: "arrow.left").font(.title2).hidden() // Giữ chỗ cho cân đối
                Spacer()
                Text("Bình luận")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Image(systemName: "paperplane").font(.title2)
            }
            .padding()
            .background(Color(.systemBackground))
            
            Divider()
            
            // --- PHẦN 2: DANH SÁCH COMMENT (Cuộn được) ---
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    // Caption của chủ bài viết (thường nằm đầu tiên)
                    CommentRow(comment: Comment(uid:"1231213",username: "wife_meoz", content: "Đỉnh quá bạn ơi! 😍", profileImageUrl: "person.crop.circle.fill", likeCount: 12))
                        .padding(.bottom, 10)
                    
                    Divider().padding(.leading, 60) // Kẻ mờ
                    
                    // Danh sách comment của người khác
                    ForEach(mockComments) { comment in
                        CommentRow(comment: comment)
                    }
                }
                .padding(.top, 10)
            }
            
            // --- PHẦN 3: Ô NHẬP LIỆU (Dính dưới đáy) ---
            // Gọi lại cái View nhập liệu bạn vừa làm
            CommentInputView()
        }
        .navigationBarHidden(true)
    }
}

// MARK: COMMENT
struct CommentRow: View {
    let comment: Comment
 
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 1. Avatar người comment
            Image(systemName: comment.profileImageUrl ?? "person.crop.circle.fill" )
                .resizable()
                .frame(width: 36, height: 36)
                .clipShape(Circle())
                .foregroundColor(.gray)
            
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

// MARK: COMMENT INPUT FORM
private struct CommentInputView: View {
    // 1. Biến lưu nội dung người dùng nhập
    @State private var commentText: String = ""
   
    
    // Giả lập ảnh đại diện của người đang đăng nhập (My Avatar)
    let currentUserAvatar = "person.circle.fill"
    
    var body: some View {
        VStack(spacing: 0) {
            Divider() // Đường kẻ mờ ngăn cách với nội dung bên trên
            
            HStack(alignment: .center, spacing: 12) {
                // 1. Avatar của chính mình (bên trái)
                Image(systemName: currentUserAvatar)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .foregroundColor(.gray)
                
                // 2. Ô nhập liệu (TextField)
                // text: $commentText -> Liên kết 2 chiều, gõ gì lưu vào biến đó
                TextField("Thêm bình luận cho @username...", text: $commentText)
                    .font(.subheadline)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 15)
                    .background(Color(.secondarySystemBackground)) // Màu nền xám nhạt cho ô nhập
                    .cornerRadius(20) // Bo tròn ô nhập (kiểu viên thuốc)
                
                // 3. Nút Đăng (Chỉ hiện khi có chữ)
                if !commentText.isEmpty {
                    Button(action: {
                        postComment()
                    }) {
                        Text("Đăng")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                    .transition(.opacity) // Hiệu ứng hiện dần
                    .animation(.easeInOut, value: commentText.isEmpty)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .background(Color(.systemBackground)) // Đảm bảo nền không bị trong suốt
    }
    
    // Hàm xử lý khi bấm Đăng
    func postComment() {
        print("Nội dung bình luận: \(commentText)")
        // Logic gửi lên server ở đây
        // Sau khi gửi xong thì xóa trắng ô nhập
        commentText = ""
        // Ẩn bàn phím
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}


struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
