import SwiftUI

struct CreatePostView: View {
    // --- STATE ---
    @State private var selectedImage: UIImage? = nil
    @State private var caption: String = ""
    @State private var showImagePicker = false
    
    // Quản lý Focus và Dismiss
    @FocusState private var isFocused: Bool
    @Environment(\.presentationMode) var presentationMode
    
    // Fix lỗi nền TextEditor
    init() {
        UITextView.appearance().backgroundColor = .clear
    }
    
    var body: some View {
        // ❌ KHÔNG DÙNG NavigationView nữa
        // ✅ Dùng VStack để tự xếp layout
        VStack(spacing: 0) {
            
            // 1. GỌI CUSTOM HEADER (Thay cho .toolbar)
            CustomToolbarView(
                onCancel: { presentationMode.wrappedValue.dismiss() },
                onPost: { handlePost() },
                canPost: selectedImage != nil // Chỉ cho post khi có ảnh
            )
            
            Divider() // Đường kẻ ngăn cách header
            
            // 2. NỘI DUNG CHÍNH (Cuộn được)
            ScrollView {
                VStack(spacing: 24) {
                    // View con chọn ảnh
                    PostImagePickerView(
                        selectedImage: selectedImage,
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
        .background(Color(.systemBackground)) // Đảm bảo nền không trong suốt
        // Sheet chọn ảnh (Vẫn cần thiết)
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
    }
    
    func handlePost() {
        print("Đang đăng bài...")
        presentationMode.wrappedValue.dismiss()
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

// MARK: - 2. VIEW CON: CHỌN ẢNH
struct PostImagePickerView: View {
    let selectedImage: UIImage?
    @Binding var showImagePicker: Bool
    
    var body: some View {
        if let uiImage = selectedImage {
            ZStack(alignment: .topTrailing) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 350)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .clipped()
                
                Button(action: { showImagePicker = true }) {
                    Image(systemName: "pencil.circle.fill")
                        .renderingMode(.original)
                        .font(.system(size: 30))
                        .foregroundColor(.blue)
                        .background(Color.white.clipShape(Circle()))
                        .shadow(radius: 2)
                        .padding(8)
                }
            }
        } else {
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
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 44))
                            .foregroundColor(.blue)
                        Text("Nhấn để thêm ảnh")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
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

// Preview
struct CreatePostView_Previews: PreviewProvider {
    static var previews: some View {
        CreatePostView()
    }
}
