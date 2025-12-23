//
//  EditPostView.swift
//  IOSSocialMedia
//
//  Created on 23/12/25.
//

import SwiftUI

struct EditPostView: View {
    let post: Post
    var onUpdate: (String, [String]?) -> Void
    
    @Environment(\.dismiss) var dismiss
    
    // --- STATE ---
    @State private var caption: String
    
    // Danh sách ảnh
    @State private var selectedImages: [UIImage] = []
    @State private var newPhotos: [UIImage] = []
    
    // Loading State
    @State private var showImagePicker = false
    @State private var isSaving = false       // Loading khi bấm LƯU
    @State private var isLoadingImages = true // Loading khi ĐANG LẤY ẢNH CŨ
    
    init(post: Post, onUpdate: @escaping (String, [String]?) -> Void) {
        self.post = post
        self.onUpdate = onUpdate
        _caption = State(initialValue: post.caption)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(spacing: 20) {
                        // 1. Ô nhập Caption
                        VStack(alignment: .leading) {
                            Text("Nội dung")
                                .font(.caption).foregroundColor(.gray)
                            TextField("Nhập nội dung mới...", text: $caption)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        Divider()
                        
                        // 2. Khu vực sửa ảnh
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Hình ảnh")
                                    .font(.caption).foregroundColor(.gray)
                                Spacer()
                                if !isLoadingImages {
                                    Text("\(selectedImages.count)/5")
                                        .font(.caption).foregroundColor(.gray)
                                }
                            }
                            
                            // 👇 CHECK LOADING ẢNH Ở ĐÂY
                            if isLoadingImages {
                                HStack {
                                    Spacer()
                                    VStack(spacing: 8) {
                                        ProgressView()
                                        Text("Đang tải ảnh cũ...")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                }
                                .frame(height: 120) // Chiều cao tương đương lưới ảnh
                                .background(Color(.secondarySystemBackground).opacity(0.3))
                                .cornerRadius(8)
                            } else {
                                // Khi tải xong thì hiện lưới ảnh
                                PostImagePickerView(
                                    selectedImages: $selectedImages,
                                    showImagePicker: $showImagePicker
                                )
                            }
                        }
                    }
                    .padding()
                }
                
                // Loading Overlay (Khi bấm Lưu)
                if isSaving {
                    ZStack {
                        Color.black.opacity(0.4).ignoresSafeArea()
                        ProgressView("Đang lưu...")
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                    }
                }
            }
            .navigationTitle("Chỉnh sửa bài viết")
            .navigationBarTitleDisplayMode(.inline)
            
            // --- TOOLBAR ---
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Hủy") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Lưu") {
                        saveChanges()
                    }
                    // Disable khi đang tải ảnh hoặc đang lưu
                    .disabled(isSaving || isLoadingImages || selectedImages.isEmpty)
                }
            }
            
            // --- SHEET CHỌN ẢNH ---
            .sheet(isPresented: $showImagePicker, onDismiss: {
                if !newPhotos.isEmpty {
                    selectedImages.append(contentsOf: newPhotos)
                    newPhotos.removeAll()
                }
            }) {
                UniversalImagePicker(
                    selectedImages: $newPhotos,
                    limit: 5 - selectedImages.count
                )
            }
            
            // --- LOAD ẢNH CŨ ---
            .onAppear {
                loadExistingImages()
            }
        }
    }
    
    // MARK: - LOGIC FUNCTIONS
    
    // 👇 Hàm này đã được viết lại để chạy Background Task (Không đơ màn hình)
    func loadExistingImages() {
            // Nếu đã có ảnh rồi thì không load lại
            if !selectedImages.isEmpty {
                isLoadingImages = false
                return
            }
            
            isLoadingImages = true
            
            Task(priority: .userInitiated) {
                var tempImages: [UIImage] = [] // 1. Dùng biến tạm để xử lý
                
                for base64String in post.imageUrls {
                    if let data = Data(base64Encoded: base64String),
                       let image = UIImage(data: data) {
                        tempImages.append(image)
                    }
                }
                
                // 2. QUAN TRỌNG: "Đóng băng" dữ liệu bằng cách gán sang 'let'
                // Swift sẽ hiểu đây là dữ liệu cố định, an toàn để chuyển sang Main Thread
                let finalImages = tempImages
                
                await MainActor.run {
                    // 3. Sử dụng biến 'finalImages' (là let) thay vì biến 'tempImages' (là var)
                    self.selectedImages = finalImages
                    self.isLoadingImages = false
                }
            }
        }
    
    func saveChanges() {
        guard let postId = post.id else { return }
        isSaving = true // Bật loading Save
        
        Task {
            do {
                try await PostService.shared.updatePost(
                    postId: postId,
                    caption: caption,
                    images: selectedImages
                )
                
                await MainActor.run {
                    isSaving = false
                    
                    // Tạo dữ liệu giả để update UI ngay
                    let newBase64Strings = selectedImages.compactMap { img -> String? in
                        return img.resized(toWidth: 600)?.jpegData(compressionQuality: 0.5)?.base64EncodedString()
                    }
                    
                    onUpdate(caption, newBase64Strings)
                    dismiss()
                }
            } catch {
                print("❌ Lỗi update: \(error)")
                await MainActor.run { isSaving = false }
            }
        }
    }
}
