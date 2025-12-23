import SwiftUI

import SwiftUI

struct CreatePostView: View {
//    @Binding var selectedTab: MainTab

    // --- STATE ---
    // 👇 Sửa thành mảng ảnh để chứa nhiều ảnh
    @State private var selectedImages: [UIImage] = []
    
    @State private var caption: String = ""
    @State private var showImagePicker = false
    @State private var isLoading = false
    
    // Alert state
    @State private var showError = false
    @State private var errorMessage = ""
    
    // Quản lý Focus và Dismiss
    @FocusState private var isFocused: Bool
    @Environment(\.presentationMode) var presentationMode
    
    init(
    ) {
//        self._selectedTab = selectedTab
        UITextView.appearance().backgroundColor = .clear
    }
    
    var body: some View {
        VStack(spacing: 0) {
            
            // 1. HEADER
            CustomToolbarView(
                onCancel: { presentationMode.wrappedValue.dismiss() },
                onPost: { handlePost() },
                // Chỉ cho post khi có ít nhất 1 ảnh
                canPost: !selectedImages.isEmpty
            )
            
            Divider()
            
            // 2. NỘI DUNG CHÍNH
            ScrollView {
                VStack(spacing: 24) {
                    // View con hiển thị ảnh (đã chọn)
                    PostImagePickerView(
                        selectedImages: $selectedImages,
                        showImagePicker: $showImagePicker
                    )
                    
                    Divider()
                    
                    // View con nhập text
                    PostCaptionInputView(
                        caption: $caption,
                        isFocused: $isFocused
                    )
                }
                .padding()
            }
        }
        .background(Color(.systemBackground))
        // 👇 Gọi ImagePicker hỗ trợ NHIỀU ẢNH
        .sheet(isPresented: $showImagePicker) {
            // limit: 0 là không giới hạn, 5 là tối đa 5 ảnh
            UniversalImagePicker(selectedImages: $selectedImages, limit: 5)
        }
        // Loading Overlay
        .overlay {
            if isLoading {
                ZStack {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    ProgressView("Đang đăng...")
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                }
            }
        }
        // Alert Báo lỗi
        .alert("Lỗi", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // HÀM UPLOAD POST (Hỗ trợ nhiều ảnh)
    func handlePost() {
        guard !selectedImages.isEmpty else { return }
        
        isLoading = true
        
        Task {
            do {
                try await PostService.shared.uploadPost(
                    caption: caption,
                    images: selectedImages
                )
                
                // ✅ 1. Clear input (PHẢI ở MainActor)
                await MainActor.run {
                    caption = ""
                    selectedImages.removeAll()
                    isFocused = false
                }
//                selectedTab = .home

                // ✅ 2. Tắt loading
                isLoading = false

                // ✅ 3. Chuyển màn (quay về Feed)
                presentationMode.wrappedValue.dismiss()

            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

// MARK: - 1. CUSTOM TOOLBAR (Thanh tiêu đề tự chế)
struct CustomToolbarView: View {
    var onCancel: () -> Void
    var onPost: () -> Void
    var canPost: Bool
    
    var body: some View {
        HStack {
            // Nút Trái: Hủy
            Button(action: onCancel) {
                Text("Hủy")
                    .font(.body)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            // Giữa: Tiêu đề
            Text("Bài viết mới")
                .font(.headline)
                .fontWeight(.bold)
            
            Spacer()
            
            // Nút Phải: Chia sẻ
            Button(action: onPost) {
                Text("Chia sẻ")
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundColor(canPost ? .blue : .gray.opacity(0.5))
            }
            .disabled(!canPost)
        }
        .padding(.horizontal)
        .padding(.vertical, 12) // Chiều cao của header
        .background(Color(.systemBackground))
    }
}

// MARK: - 2. VIEW CON: CHỌN ẢNH c1
//struct PostImagePickerView: View {
//    let selectedImages: [UIImage] // Nhận mảng ảnh
//    @Binding var showImagePicker: Bool
//    
//    var body: some View {
//        if !selectedImages.isEmpty {
//            // TRƯỜNG HỢP: Đã chọn ảnh -> Hiện Slider lướt ngang
//            ZStack(alignment: .topTrailing) {
//                
//                TabView {
//                    ForEach(0..<selectedImages.count, id: \.self) { index in
//                        Image(uiImage: selectedImages[index])
//                            .resizable()
//                            .scaledToFill()
//                            .frame(height: 350)
//                            .clipped()
//                            // 👇 Tag quan trọng để TabView chạy đúng
//                            .tag(index)
//                    }
//                }
//                .tabViewStyle(PageTabViewStyle()) // Hiện dấu chấm tròn
//                .frame(height: 350)
//                .clipShape(RoundedRectangle(cornerRadius: 12))
//                
//                // Nút Sửa ảnh (Góc trên phải)
//                Button(action: { showImagePicker = true }) {
//                    Image(systemName: "pencil.circle.fill")
//                        .font(.system(size: 30))
//                        .foregroundColor(.blue)
//                        .background(Color.white.clipShape(Circle()))
//                        .shadow(radius: 2)
//                        .padding(10)
//                }
//            }
//        } else {
//            // TRƯỜNG HỢP: Chưa chọn ảnh -> Hiện nút thêm
//            Button(action: { showImagePicker = true }) {
//                ZStack {
//                    RoundedRectangle(cornerRadius: 12)
//                        .fill(Color(.secondarySystemBackground))
//                        .frame(height: 250)
//                    
//                    RoundedRectangle(cornerRadius: 12)
//                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [6]))
//                        .foregroundColor(.gray.opacity(0.5))
//                        .frame(height: 250)
//                    
//                    VStack(spacing: 12) {
//                        Image(systemName: "photo.on.rectangle")
//                            .font(.system(size: 44))
//                            .foregroundColor(.blue)
//                        Text("Nhấn để chọn ảnh")
//                            .font(.headline)
//                            .foregroundColor(.gray)
//                    }
//                }
//            }
//        }
//    }
//}


// MARK: - 2. VIEW CON: CHỌN ẢNH (Dạng Lưới)
struct PostImagePickerView: View {
    @Binding var selectedImages: [UIImage] // Dùng Binding để có thể xóa ảnh
    @Binding var showImagePicker: Bool
    
    // Cấu hình lưới: 3 cột, khoảng cách 2px
    let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]
    
    var body: some View {
        if !selectedImages.isEmpty {
            VStack(alignment: .leading) {
                // Tiêu đề nhỏ
                HStack {
                    Text("Ảnh đã chọn (\(selectedImages.count))")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    // Nút thêm ảnh
                    Button(action: { showImagePicker = true }) {
                        Label("Thêm", systemImage: "plus")
                            .font(.caption.bold())
                    }
                }
                .padding(.bottom, 5)
                
                // --- LƯỚI ẢNH ---
                LazyVGrid(columns: columns, spacing: 2) {
                    // Duyệt qua mảng ảnh kèm Index để xử lý xóa
                    ForEach(0..<selectedImages.count, id: \.self) { index in
                        ZStack(alignment: .topTrailing) {
                            
                            // 1. Hình ảnh
                            Image(uiImage: selectedImages[index])
                                .resizable()
                                .scaledToFill()
                                .frame(width: (UIScreen.main.bounds.width - 40) / 3, height: 120) // Chia 3 cột
                                .clipped()
                                .cornerRadius(4)
                            
                            // 2. Nút Xóa (Dấu X góc phải)
                            Button(action: {
                                withAnimation {
                                    removeImage(at: index)
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white)
                                    .background(Color.black.opacity(0.6).clipShape(Circle()))
                                    .padding(4)
                            }
                        }
                    }
                }
            }
        } else {
            // TRƯỜNG HỢP: Chưa chọn ảnh (Giữ nguyên giao diện cũ)
            Button(action: { showImagePicker = true }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                        .frame(height: 250)
                    
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [6]))
                        .foregroundColor(.gray.opacity(0.5))
                        .frame(height: 250)
                    
                    VStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 44))
                            .foregroundColor(.blue)
                        Text("Nhấn để chọn ảnh")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
    
    // Hàm xóa ảnh khỏi mảng
    func removeImage(at index: Int) {
        guard index < selectedImages.count else { return }
        selectedImages.remove(at: index)
    }
}
// MARK: - 3. VIEW CON: NHẬP TEXT
struct PostCaptionInputView: View {
    @Binding var caption: String
    var isFocused: FocusState<Bool>.Binding
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Chú thích")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            ZStack(alignment: .topLeading) {
                if caption.isEmpty {
                    Text("Viết chú thích cho bài viết...")
                        .foregroundColor(Color(.placeholderText))
                        .padding(.top, 8)
                        .padding(.leading, 5)
                }
                
                TextEditor(text: $caption)
                    .focused(isFocused)
                    .frame(minHeight: 120)
                    .padding(4)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
            }
        }
    }
}

//// Preview
//struct CreatePostView_Previews: PreviewProvider {
//    static var previews: some View {
//        CreatePostView()
//    }
//}
